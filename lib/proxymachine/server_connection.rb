class ProxyMachine
  class ServerConnection < EventMachine::Connection
    def self.request(host, port, client_side)
      EventMachine.connect(host, port, self, client_side)
    end

    def initialize(conn)
      @client_side = conn
      @connected = false
      @proxy_started = false
      @timeout = nil
      @buffer = []
    end

    def peer
      @peer ||=
      begin
        port, ip = Socket.unpack_sockaddr_in(get_peername)
        "#{ip}:#{port}"
      end
    end

    def receive_data(data)
      fail "receive_data called after raw proxy enabled" if @proxy_started
      @buffer << data
      proxy_server_data
    end

    def proxy_server_data
      if ProxyMachine.relay
        commands = ProxyMachine.relay.call(@buffer.join)
        LOGGER.info "#{peer} #{commands.inspect}"
        close_connection unless commands.instance_of?(Hash)
        if data = commands[:proxy]
          @proxy_started = true
          @buffer = []
          @client_side.send_data(data)
          proxy_incoming_to(@client_side, 10240)
        elsif commands[:noop]
          # do nothing
        else
          close_connection
        end
      else
        @proxy_started = true
        @buffer.each { |data| @client_side.send_data(data) }
        @buffer = []
        proxy_incoming_to(@client_side, 10240)
      end
    end

    def connection_completed
      @connected = Time.now
      @timeout = comm_inactivity_timeout || 0.0
      @client_side.server_connection_success
    end

    def unbind
      now = Time.now
      if @client_side.error?
        # the client side disconnected while we were in progress with
        # the server. do nothing.
        LOGGER.info "Client closed while server connection in progress. Dropping."
      elsif !@connected
        # a connection error or timeout occurred
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
