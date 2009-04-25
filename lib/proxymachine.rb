require 'rubygems'
require 'eventmachine'

require 'proxymachine/client_connection'
require 'proxymachine/server_connection'

class ProxyMachine
  def self.set_router(block)
    @@router = block
  end
  
  def self.router
    @@router
  end
  
  def self.run
    EM.run do
      EventMachine::Protocols::ClientConnection.start
    end
  end
end

module Kernel
  def proxy(&block)
    ProxyMachine.set_router(block)
  end
end