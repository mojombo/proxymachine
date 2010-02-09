require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'socket'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
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

ppid = Process.pid

# Start the simple proxymachine
fork do
  harikari(ppid)
  load(File.join(File.dirname(__FILE__), *%w[configs simple.rb]))
  ProxyMachine.run('simple', 'localhost', 9990)
end

# Start two test daemons
[9980, 9981].each do |port|
  fork do
    harikari(ppid)
    EM.run do
      EventMachine::Protocols::TestConnection.start('localhost', port)
    end
  end
end
