require 'rubygems'
require 'em-websocket'
require 'json'

class Action
  @@users = {}
  
  class << self
    def users
      return @@users
    end
    
    def parse_message message, socket
      user, data = JSON.parse! message
      return Action.send(data['cmd'], user, data, socket)
    end
    
    def connect(user, data, socket)
      @@users[user] = socket unless @@users.include? user
      return "#{user} connected"
    end
    
    def message(user, data, socket)
      return format("%s: %s", user, data['body']) # "%s" % ['foo']
    end
  end
end

EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 1234) do |socket|

  socket.onopen { 
    puts "New connection"
    puts socket.request.inspect
    # @sockets ||= []
    # @sockets << socket
  }

  socket.onmessage  { |msg|
    message = Action.parse_message msg, socket
    unless message.nil?
      Action.users.each do |user, ws|
        ws.send "#{message}"
      end
    end
  }
  socket.onclose { 
    puts "Connection closed"
    # @sockets.delete socket
    #socket.onmessage("Someone disconnected.")
  }
end
