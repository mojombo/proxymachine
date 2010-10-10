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

def harikari(ppid)
  Thread.new do
    loop do
      begin
        Process.kill(0, ppid)
      rescue
        exit
      end
      sleep 1
    end
  end
end

class PMTest < Test::Unit::TestCase

  def harikari(ppid)
    Thread.new do
      loop do
        begin
          Process.kill(0, ppid)
        rescue
          exit
        end
        sleep 1
      end
    end
  end

  def run(*)
    localhost = '127.0.0.1'
    ppid = Process.pid
    @cpids = []

    # Start the simple proxymachine
    @cpids << fork do
      harikari(ppid)
      load(File.join(File.dirname(__FILE__), *%w[configs simple.rb]))
      trap(:INT) { EM.stop }
      ProxyMachine.run('simple', localhost, 9990)
    end

    # Start two test daemons
    [9980, 9981].each do |port|
      @cpids << fork do
        harikari(ppid)
        EM.run do
          trap(:INT) { EM.stop }
          EventMachine::Protocols::TestConnection.start(localhost, port)
        end
      end
    end

    # Make sure processes have enough time to start
    sleep 0.05

    super
  ensure
    @cpids.each do |pid|
      Process.kill(:INT, pid)
      Process.waitpid(pid)
    end
  end
  
  def test_sanity
    assert_equal 3, @cpids.size
  end

  def assert_proxy(host, port, send, recv)
    sock = TCPSocket.new(host, port)
    sock.write(send)
    assert_equal recv, sock.read
    sock.close
  end
end
