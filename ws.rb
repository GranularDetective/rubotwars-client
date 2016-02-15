require 'faye/websocket'
require 'eventmachine'
require 'json'

key1 = 'a37717f37f8d2f8ea355'
key2 = 'a6715afbd291f71bdb52'
key = key1

server = 'ws://localhost:3000/cable/'

EM.run {
  ws = Faye::WebSocket::Client.new(server, nil, { headers: {'user-key' => key }} )

  channel_id = { channel: 'MatchChannel' }.to_json

  ws.on :open do |event|
    ws.send({ command: 'subscribe', identifier: channel_id }.to_json)
  end

  ws.on :message do |event|
    data = JSON.parse(event.data)
    if data.key?('message') && data['message'].is_a?(Hash) && data['message'].key?('action')
      case data['message']['action']
      when 'urmove'
        p 'Moving'
        payload = { action: 'perform_move', direction: 'up' }.to_json
        ws.send({ command: 'message', identifier: channel_id, data: payload }.to_json)
      else
        p data['message']['action']
      end
    end
  end

  ws.on :close do |event|
    p [:close, event.code, event.reason]
    ws = nil
  end
}
