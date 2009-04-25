module EventMachine
  module Protocols
    class ServerConnection < Connection
      def self.request(host, port, client_side)
        EventMachine.connect(host, port, self) do |c|
          # According to the docs, we will get here AFTER post_init is called.
          c.set_client_side(client_side)
        end
      end

      def set_client_side(conn)
        @client_side = conn
      end

      def receive_data(data)
        # p data
        @client_side.send_data(data)
      end

      def unbind
        @client_side.close_connection
      end
    end
  end
end