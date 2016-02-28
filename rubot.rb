require 'faye/websocket'
require 'eventmachine'
require 'json'
require 'securerandom'

class Rubot
  def initialize
    @name = 'AnonyBot'
    @server = 'ws://localhost:3000/cable/'
    @channel_id = { channel: 'MatchChannel' }.to_json
    @client_key = SecureRandom.base64
    @bot_thread = nil
    @response_queue = []
    trap('INT') { EM.stop }
    EM.run do
      @send_queue = EM::Queue.new
      start_client
    end
  end

  def bot_loop
    case scan
    when 'enemy'
      fire
    when 'empty'
      move_forward
    else
      turn(:left)
    end
  end

  def scan
    puts 'Scanning'
    send(action: 'scan')
    wait_for_response
  end

  def turn(direction)
    puts "Turn #{direction.to_s}"
    send(action: 'turn', direction: direction)
    wait_for_response
  end

  def move_forward
    puts 'Move forward'
    send(action: 'move_forward')
    wait_for_response
  end

  def fire
    puts 'Fire!'
    send(action: 'fire')
    wait_for_response
  end

  private
  def wait_for_response
    loop do
      break if @response_queue.any?
    end
    @response_queue.pop
  end

  def send(data)
    @send_queue.push(data)
  end

  def start_client
    ws = Faye::WebSocket::Client.new(@server, nil, headers: { 'user-key' => @client_key, 'user-name' => @name })

    send_data = proc do |data|
      ws.send({ command: 'message', identifier: @channel_id, data: data.to_json }.to_json)
      EM.next_tick { @send_queue.pop(&send_data) }
    end
    @send_queue.pop(&send_data)

    ws.on :open do
      payload = { name: @name }.to_json
      ws.send({ command: 'subscribe', identifier: @channel_id, data: payload }.to_json)
    end

    ws.on :message do |event|
      data = JSON.parse(event.data)
      if data.key?('message') && data['message'].is_a?(Hash) && data['message'].key?('action')
        case data['message']['action']
        when 'start'
          @bot_thread = Thread.new { loop { bot_loop } }
        when 'response'
          @response_queue << data['message']['result']
        else
          p "Unknown action: #{data['message']['action']}"
        end
      end
    end

    ws.on :close do
      @bot_thread.exit
      ws = nil
    end
  end

end


Rubot.new
