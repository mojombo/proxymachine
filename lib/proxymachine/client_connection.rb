module EventMachine
  module Protocols
    class ClientConnection < Connection
      def self.start
        EM.start_server("localhost", 5432, self)
      end

      def post_init
        @data = []
      end

      def receive_data(data)
        if @server_side
          p data
          @server_side.send_data(data)
        else
          op = ProxyMachine.router.call('', 0, data)
          if op.instance_of?(String)
            m, host, port = *op.match(/^(.+):(.+)$/)
            @server_side = ServerConnection.request(host, port.to_i, self)
            @server_side.send_data(data)
          else
            @data << data
          end
        end
      end
    end
  end
end