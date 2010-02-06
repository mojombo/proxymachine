class ProxyMachine
  class ServerConnection < EventMachine::Connection
    def self.request(host, port, client_side)
      EventMachine.connect(host, port, self, client_side)
    end

    def initialize(conn)
      @client_side = conn
      @connected = false
      @data_received = false
      @timeout = nil
    end

    def receive_data(data)
      fail "receive_data called after raw proxy enabled" if @data_received
      @data_received = true
      @client_side.send_data(data)
      proxy_incoming_to @client_side
    end

    def connection_completed
      @connected = Time.now
      @timeout = comm_inactivity_timeout || 0.0
      @client_side.server_connection_success
    end

    def unbind
      now = Time.now
      if !@connected
        @client_side.server_connection_failed
      elsif !@data_received
        if @timeout > 0.0 && (elapsed = now - @connected) >= @timeout
          # EM aborted the connection due to an inactivity timeout
          @client_side.server_inactivity_timeout(@timeout, elapsed)
        else
          # server disconnected soon after connecting without sending data
          # treat this like a failed server connection
          @client_side.server_connection_failed
        end
      else
        @client_side.close_connection_after_writing
      end
    end
  end
end
