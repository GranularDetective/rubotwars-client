require 'faye/websocket'
require 'eventmachine'
require 'json'
require 'securerandom'



class Rubot
  def initialize
    @name = 'AnonyBot'
    @server = 'ws://localhost:3000/cable/'
    @responses = []
    start_client
  end

  def bot_loop
    case scan
    when :enemy
      fire
    when :empty
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

  def wait_for_response
    loop do
      break if @responses.any?
      sleep 0.2
    end
    @responses.pop
  end

  def send(data)
    @ws.send({ command: 'message', identifier: @channel_id, data: data.to_json }.to_json)
  end

  def start_client
    @channel_id = { channel: 'MatchChannel' }.to_json
    client_key = SecureRandom.base64
    EM.run do
      @ws = Faye::WebSocket::Client.new(@server, nil, headers: { 'user-key' => client_key })

      @ws.on :open do
        payload = { name: @name }.to_json
        @ws.send({ command: 'subscribe', identifier: @channel_id, data: payload }.to_json)
      end

      @ws.on :message do |event|
        data = JSON.parse(event.data)
        if data.key?('message') && data['message'].is_a?(Hash) && data['message'].key?('action')
          case data['message']['action']
          when 'urmove'
            bot_loop
          when 'response'
            @responses << data['message']['result']
          else
            p data['message']['action']
          end
        end
      end

      @ws.on :close do
        @ws = nil
      end
    end
  end

end


Rubot.new
