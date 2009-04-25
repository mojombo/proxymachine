module EventMachine
  module Protocols
    class ServerConnection < Connection
      def self.request(client_side)
        EventMachine.connect("localhost", 3000, self) do |c|
          # According to the docs, we will get here AFTER post_init is called.
          c.set_client_side(client_side)
        end
      end

      def set_client_side(conn)
        @client_side = conn
      end

      def receive_data(data)
        p data
        @client_side.send_data(data)
      end
    end
  end
end