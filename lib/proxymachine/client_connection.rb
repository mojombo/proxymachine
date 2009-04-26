module EventMachine
  module Protocols
    class ClientConnection < Connection
      def self.start(host, port)
        EM.start_server(host, port, self)
        puts "Listening on #{host}:#{port}"
      end

      def post_init
        @buffer = []
        @tries = 0
        ProxyMachine.incr
      end

      def receive_data(data)
        if !@server_side
          @buffer << data
          ensure_server_side_connection
        else @server_side
          # p data
          @server_side.send_data(data)
        end
      rescue => e
        close_connection
        puts "#{e.class} - #{e.message}"
      end

      def ensure_server_side_connection
        @timer.cancel if @timer
        unless @server_side
          op = ProxyMachine.router.call(@buffer.join)
          if op.instance_of?(String)
            m, host, port = *op.match(/^(.+):(.+)$/)
            if try_server_connect(host, port.to_i)
              send_and_clear_buffer
            end
          elsif op == :noop
            # do nothing
          else
            close_connection
          end
        end
      end

      def try_server_connect(host, port)
        @server_side = ServerConnection.request(host, port, self)
        if @tries > 0
          puts "Successful connection."
        end
        true
      rescue => e
        if @tries < 10
          @tries += 1
          puts "Failed on server connect attempt #{@tries}. Trying again..."
          @timer.cancel if @timer
          @timer = EventMachine::Timer.new(0.1) do
            self.ensure_server_side_connection
          end
        else
          puts "Failed after ten connection attempts."
        end
        false
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
        @server_side.close_connection_after_writing if @server_side
        ProxyMachine.decr
      end
    end
  end
end