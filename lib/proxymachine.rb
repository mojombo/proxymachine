require 'rubygems'
require 'eventmachine'

require 'proxymachine/client_connection'
require 'proxymachine/server_connection'

class ProxyMachine
  MAX_FAST_SHUTDOWN_SECONDS = 10

  def self.update_procline
    $0 = "proxymachine #{VERSION} - #{@@name} #{@@listen} - #{self.count}/#{@@totalcounter} connections"
  end

  def self.count
    @@counter
  end

  def self.incr
    @@totalcounter += 1
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
    @@totalcounter = 0
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

  def self.version
    yml = YAML.load(File.read(File.join(File.dirname(__FILE__), *%w[.. VERSION.yml])))
    "#{yml[:major]}.#{yml[:minor]}.#{yml[:patch]}"
  rescue
    'unknown'
  end

  VERSION = self.version
end

module Kernel
  def proxy(&block)
    ProxyMachine.set_router(block)
  end
end