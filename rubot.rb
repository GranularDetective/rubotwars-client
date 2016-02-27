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
    EM.run do
      @response_queue = EM::Queue.new
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
    send(action: 'scan')
    wait_for_response
  end

  def turn(direction)
    send(action: 'turn', direction: direction)
    wait_for_response
  end

  def move_forward
    send(action: 'move_forward')
    wait_for_response
  end

  def fire
    send(action: 'fire')
    wait_for_response
  end

  private

  # A way to block this untill there is a response?!
  def wait_for_response
    @response_queue.pop(proc { |data| return data })
  end

  def send(data)
    @send_queue.push(data)
  end

  def start_client
    ws = Faye::WebSocket::Client.new(@server, nil, headers: { 'user-key' => @client_key, 'user-name' => @name })

    send_data = proc do |data|
      p "Sending #{data.inspect} "
      ws.send({ command: 'message', identifier: @channel_id, data: data.to_json }.to_json)
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
          bot_loop
        when 'response'
          @response_queue.push(data['message']['result'])
        else
          p "Unknown action: #{data['message']['action']}"
        end
      end
    end

    ws.on :close do
      EM.cancel_timer(send_loop)
      ws = nil
    end
  end

end


Rubot.new
