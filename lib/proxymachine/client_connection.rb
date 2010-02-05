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
      @tries = 0
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
      if !@server_side
        @buffer << data
        ensure_server_side_connection
      end
    rescue => e
      close_connection
      LOGGER.info "#{e.class} - #{e.message}"
    end

    def ensure_server_side_connection
      @timer.cancel if @timer
      unless @server_side
        commands = ProxyMachine.router.call(@buffer.join)
        LOGGER.info "#{peer} #{commands.inspect}"
        close_connection unless commands.instance_of?(Hash)
        if remote = commands[:remote]
          m, host, port = *remote.match(/^(.+):(.+)$/)
          @server_side = ServerConnection.request(host, port, self)
          if data = commands[:data]
            @buffer = [data]
          end
          if reply = commands[:reply]
            send_data(reply)
          end
          @buffer.each { |data| @server_side.send_data(data) }
          proxy_incoming_to @server_side

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
