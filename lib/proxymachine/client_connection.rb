class ProxyMachine
  class ClientConnection < EventMachine::Connection
    def self.start(host, port)
      $server = EM.start_server(host, port, self)
      LOGGER.info "Listening on #{host}:#{port}"
      LOGGER.info "Send QUIT to quit after waiting for all connections to finish."
      LOGGER.info "Send TERM or INT to quit after waiting for up to 10 seconds for connections to finish."
    end

    def post_init
      LOGGER.info "Accepted #{peer}"
      @buffer = []
      @remote = nil
      @tries = 0
      @connected = false
      @connect_timeout = nil
      @inactivity_timeout = nil
      ProxyMachine.incr
    end

    def peer
      @peer ||=
      begin
        port, ip = Socket.unpack_sockaddr_in(get_peername)
        "#{ip}:#{port}"
      end
    end

    def receive_data(data)
      if !@connected
        @buffer << data
        establish_remote_server if @remote.nil?
      end
    rescue => e
      close_connection
      LOGGER.info "#{e.class} - #{e.message}"
    end

    # Called when new data is available from the client but no remote
    # server has been established. If a remote can be established, an
    # attempt is made to connect and proxy to the remote server.
    def establish_remote_server
      fail "establish_remote_server called with remote established" if @remote
      commands = ProxyMachine.router.call(@buffer.join)
      LOGGER.info "#{peer} #{commands.inspect}"
      close_connection unless commands.instance_of?(Hash)
      if remote = commands[:remote]
        m, host, port = *remote.match(/^(.+):(.+)$/)
        @remote = [host, port]
        if data = commands[:data]
          @buffer = [data]
        end
        if reply = commands[:reply]
          send_data(reply)
        end
        @connect_timeout = commands[:connect_timeout]
        @inactivity_timeout = commands[:inactivity_timeout]
        connect_to_server
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

    # Connect to the remote server
    def connect_to_server
      fail "connect_server called without remote established" if @remote.nil?
      host, port = @remote
      LOGGER.info "Establishing new connection with #{host}:#{port}"
      @server_side = ServerConnection.request(host, port, self)
      @server_side.pending_connect_timeout = @connect_timeout
      @server_side.comm_inactivity_timeout = @inactivity_timeout
    end

    # Called by the server side immediately after the server connection was
    # successfully established. Send any buffer we've accumulated and start
    # raw proxying.
    def server_connection_success
      LOGGER.info "Successful connection to #{@remote.join(':')}"
      @connected = true
      @buffer.each { |data| @server_side.send_data(data) }
      proxy_incoming_to(@server_side, 10240)
    end

    # Called by the server side when a connection could not be established,
    # either due to a hard connection failure or to a connection timeout.
    # Leave the client connection open and retry the server connection up to
    # 10 times.
    def server_connection_failed
      @server_side = nil
      if @tries < 10
        @tries += 1
        LOGGER.info "Retrying connection with #{@remote.join(':')} (##{@tries})"
        EM.add_timer(0.1) { connect_to_server }
      else
        LOGGER.info "Connect #{@remote.join(':')} failed after ten attempts."
        close_connection
        ProxyMachine.connect_error_callback.call(@remote.join(':'))
      end
    end

    # Called by the server when an inactivity timeout is detected. The timeout
    # argument is the configured inactivity timeout in seconds as a float; the
    # elapsed argument is the amount of time that actually elapsed since
    # connecting but not receiving any data.
    def server_inactivity_timeout(timeout, elapsed)
      LOGGER.info "Disconnecting #{@remote.join(':')} after #{elapsed}s of inactivity (> #{timeout.inspect})"
      @server_side = nil
      close_connection
      ProxyMachine.inactivity_error_callback.call(@remote.join(':'))
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
