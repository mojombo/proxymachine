module EventMachine
  module Protocols
    class ClientConnection < Connection
      def self.start(host, port)
        $server = EM.start_server(host, port, self)
        puts "Listening on #{host}:#{port}"
        puts "Send QUIT to quit after waiting for all connections to finish."
        puts "Send TERM or INT to quit after waiting for up to 10 seconds for connections to finish."
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
        end
      rescue => e
        close_connection
        puts "#{e.class} - #{e.message}"
      end

      def ensure_server_side_connection
        @timer.cancel if @timer
        unless @server_side
          commands = ProxyMachine.router.call(@buffer.join)
          close_connection unless commands.instance_of?(Hash)
          if remote = commands[:remote]
            m, host, port = *remote.match(/^(.+):(.+)$/)
            if try_server_connect(host, port.to_i)
              if data = commands[:data]
                @buffer = [data]
              end
              send_and_clear_buffer
            end
          elsif close = commands[:close]
            if close == true
              close_connection
            else
              send_data(close)
              close_connection_after_writing
            end
          elsif commands[:noop]
            # do nothing
          else
            close_connection
          end
        end
      end

      def try_server_connect(host, port)
        @server_side = ServerConnection.request(host, port, self)
        proxy_incoming_to(@server_side, 10240)
        puts "Successful connection to #{host}:#{port}."
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
            @server_side.send_data(x)
          end
          @buffer = []
        end
      end

      def unbind
        @server_side.close_connection_after_writing if @server_side
        ProxyMachine.decr
      end

      # Proxy connection has been lost
      def proxy_target_unbound
        @server_side = nil
      end
    end
  end
end
