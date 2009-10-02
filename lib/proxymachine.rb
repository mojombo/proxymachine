require 'rubygems'
require 'eventmachine'

require 'proxymachine/client_connection'
require 'proxymachine/server_connection'

class ProxyMachine
  MAX_FAST_SHUTDOWN_SECONDS = 10

  def self.update_procline
    $0 = "proxymachine - #{@@name} #{@@listen} - #{self.count} connections"
  end

  def self.count
    @@counter
  end

  def self.incr
    @@counter += 1
    self.update_procline
    @@counter
  end

  def self.decr
    @@counter -= 1
    if $server.nil?
      puts "Waiting for #{@@counter} connections to finish."
    end
    self.update_procline
    EM.stop if $server.nil? and @@counter == 0
    @@counter
  end

  def self.set_router(block)
    @@router = block
  end

  def self.router
    @@router
  end

  def self.graceful_shutdown(signal)
    EM.stop_server($server) if $server
    puts "Received #{signal} signal. No longer accepting new connections."
    puts "Waiting for #{ProxyMachine.count} connections to finish."
    $server = nil
    EM.stop if ProxyMachine.count == 0
  end

  def self.fast_shutdown(signal)
    EM.stop_server($server) if $server
    puts "Received #{signal} signal. No longer accepting new connections."
    puts "Maximum time to wait for connections is #{MAX_FAST_SHUTDOWN_SECONDS} seconds."
    puts "Waiting for #{ProxyMachine.count} connections to finish."
    $server = nil
    EM.stop if ProxyMachine.count == 0
    Thread.new do
      sleep MAX_FAST_SHUTDOWN_SECONDS
      exit!
    end
  end

  def self.run(name, host, port)
    @@counter = 0
    @@name = name
    @@listen = "#{host}:#{port}"
    self.update_procline
    EM.epoll

    EM.run do
      EventMachine::Protocols::ClientConnection.start(host, port)
      trap('QUIT') do
        self.graceful_shutdown('QUIT')
      end
      trap('TERM') do
        self.fast_shutdown('TERM')
      end
      trap('INT') do
        self.fast_shutdown('INT')
      end
    end
  end
end

module Kernel
  def proxy(&block)
    ProxyMachine.set_router(block)
  end
end