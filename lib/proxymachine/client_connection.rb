module EventMachine
  module Protocols
    class ClientConnection < Connection
      def self.start
        EM.start_server("localhost", 5432, self)
      end

      def post_init
        @server_side = ServerConnection.request(self)
      end

      def receive_data(data)
        p data
        @server_side.send_data(data)
      end
    end
  end
end