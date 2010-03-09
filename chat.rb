
require 'rubygems'
require 'em-websocket'

EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 1234, :debug => true) do |socket|
  
  socket.onopen { 
    puts "New connection"
    @sockets ||= []
    @sockets << socket
  }
  
  socket.onmessage  { |msg|
    @sockets.each do |s|
      puts s.inspect
      s.send "#{msg}"
    end
  }
  socket.onclose { 
    puts "Connection closed"
    @sockets.delete socket
  }
end
