module EventMachine
  module Protocols
    class ClientConnection < Connection
      def self.start
        EM.start_server("localhost", 5432, self)
        puts "Listening"
      end

      def post_init
        @buffer = []
        ProxyMachine.incr
      end

      def receive_data(data)
        unless @server_side
          op = ProxyMachine.router.call('', 0, data)
          if op.instance_of?(String)
            m, host, port = *op.match(/^(.+):(.+)$/)
            @server_side = ServerConnection.request(host, port.to_i, self)
            send_and_clear_buffer
          elsif op == :noop
            @buffer << data
          else
            # close
          end
        end

        if @server_side
          # p data
          @server_side.send_data(data)
        end
      rescue => e
        close_connection
        puts e.message
      end

      def send_and_clear_buffer
        if !@buffer.empty?
          @buffer.each do |x|
            # p x
            @server_side.send_data(x)
          end
          @buffer = []
        end
      end

      def unbind
        @server_side.close_connection if @server_side
        ProxyMachine.decr
      end
    end
  end
end