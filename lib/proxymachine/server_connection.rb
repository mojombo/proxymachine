class ProxyMachine
  class ServerConnection < EventMachine::Connection
    def self.request(host, port, client_side)
      EventMachine.connect(host, port, self, client_side)
    end

    def initialize(conn)
      @client_side = conn
      @connected = false
      @data_received = false
    end

    def receive_data(data)
      fail "receive_data called after raw proxy enabled" if @data_received
      @data_received = true
      @client_side.send_data(data)
      proxy_incoming_to @client_side
    end

    def connection_completed
      @connected = Time.now
      @client_side.server_connection_success
    end

    def unbind
      if !@connected
        @client_side.server_connection_failed
      elsif !@data_received && (Time.now - @connected) >= comm_inactivity_timeout
        # EM aborted the connection due to an inactivity timeout
        @client_side.server_inactivity_timeout
      else
        @client_side.close_connection_after_writing
      end
    end
  end
end
