require 'rubygems'
require 'eventmachine'

require 'proxymachine/client_connection'
require 'proxymachine/server_connection'

class ProxyMachine
  def self.count
    @@counter ||= 0
    @@counter
  end

  def self.incr
    @@counter ||= 0
    @@counter += 1
  end

  def self.decr
    @@counter ||= 0
    @@counter -= 1
    if $server.nil?
      puts "Waiting for #{@@counter} connections to finish."
    end
    EM.stop if $server.nil? and @@counter == 0
    @@counter
  end

  def self.set_router(block)
    @@router = block
  end

  def self.router
    @@router
  end

  def self.run(host, port)
    EM.epoll

    EM.run do
      EventMachine::Protocols::ClientConnection.start(host, port)
      trap('QUIT') do
        EM.stop_server($server) if $server
        puts "Received QUIT signal. No longer accepting new connections."
        puts "Waiting for #{ProxyMachine.count} connections to finish."
        $server = nil
        EM.stop if ProxyMachine.count == 0
      end
    end
  end
end

module Kernel
  def proxy(&block)
    ProxyMachine.set_router(block)
  end
end