require 'test/unit'
require 'shoulda'
require 'socket'
require 'proxymachine'

# A simple echo server to use in tests
module EventMachine
  module Protocols
    class TestConnection < Connection
      def self.start(host, port)
        @@port = port
        EM.start_server(host, port, self)
      end

      def receive_data(data)
        sleep $1.to_f if data =~ /^sleep (.*)/
        send_data("#{@@port}:#{data}")
        close_connection_after_writing
      end
    end
  end
end

require File.expand_path('../configs/simple', __FILE__)

class PMTest < Test::Unit::TestCase

  def self.servers
    @servers ||= {}
  end

  def self.spawn(&block)
    ppid = Process.pid
    pid  = fork { harikari(ppid); block.call }

    servers[pid] = block
  end

  def self.respawn
    alive   = servers.keys.find_all { |pid| Process.kill(0, pid) rescue nil }
    dead    = servers.keys - alive
    respawn = dead.map { |pid| servers.delete(pid) }

    respawn.each { |block| spawn(&block) }
  end

  def self.harikari(ppid)
    trap(:INT) { EM.stop }
    Thread.new do
      sleep 1 while Process.kill(0, ppid) rescue nil
      exit
    end
  end

  at_exit do
    servers.keys.each do |pid|
      Process.kill(:INT, pid)
      Process.waitpid(pid)
    end
  end

  def run(*)
    self.class.respawn
    super
  end

  def test_dummy; end

  def assert_proxy(host, port, send, recv)
    sock = TCPSocket.new(host, port)
    sock.write(send)
    assert_equal recv, sock.read
    sock.close
  end
end
