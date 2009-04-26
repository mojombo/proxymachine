module EventMachine
  module Protocols
    class ServerConnection < Connection
      def self.request(host, port, client_side)
        EventMachine.connect(host, port, self, client_side)
      end

      def initialize(conn)
        @client_side = conn
      end

      def receive_data(data)
        # p data
        @client_side.send_data(data)
      end

      def unbind
        @client_side.close_connection_after_writing
      end
    end
  end
end