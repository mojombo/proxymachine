require 'rubygems'
require 'eventmachine'

require 'proxymachine/client_connection'
require 'proxymachine/server_connection'

EM.run do
  EventMachine::Protocols::ClientConnection.start
end