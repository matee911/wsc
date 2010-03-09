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
      return @@users, "#{user} connected"
    end
    
    def leave(socket)
      user = @@users.index socket
      @@users.delete user
      return @@users, "%s disconnected" % [user]
    end
    
    def message(user, data, socket)
      # prv only to one user
      if data['body'].strip[0].chr == '^' # taak, wesołe miasteczko
        rcpt_to = data['body'].strip.split.first[1..-1] # i tu
        if @@users.member? rcpt_to
          return {rcpt_to => @@users[rcpt_to], user => socket}, format("%s: %s", user, data['body'])
        else
          return {user => socket}, "Message to unknown recipient %s: %s" % [rcpt_to, data['body']]
        end
      end
      # all users
      return @@users, format("%s: %s", user, data['body']) # "%s" % ['foo']
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
    users, message = Action.parse_message msg, socket
    unless message.nil?
      users.each do |user, ws|
        ws.send "#{message}"
      end
    end
  }
  socket.onclose {
    users, message = Action.leave socket
    unless message.nil?
      users.each do |user, ws|
        ws.send "#{message}"
      end
    end
    puts "Connection closed"
  }
end
