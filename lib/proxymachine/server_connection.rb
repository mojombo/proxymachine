module ProxyMachine
  class ServerConnection < EventMachine::Connection
    def self.request(host, port, client_side)
      EventMachine.connect(host, port, self, client_side)
    end

    def initialize(conn)
      @client_side = conn
    end

    def post_init
      proxy_incoming_to(@client_side, 10240)
    end

    def unbind
      @client_side.close_connection_after_writing
    end
  end
end
