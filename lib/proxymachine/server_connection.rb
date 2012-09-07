#require 'pry'
class ProxyMachine
  class ServerConnection < EventMachine::Connection
    def self.request(host, port, client_side,bind_addr=nil,bind_port=nil)
     # binding.pry
      #LOGGER.debug "Local bind: #{bind_addr} #{bind_port}"
      if bind_addr or bind_port then 
        LOGGER.info "Local bind: #{bind_addr} #{bind_port}"
      else
        LOGGER.debug "No local binding specified" #FIXME: remove this
      end
      EventMachine.bind_connect(bind_addr,bind_port,host, port, self, client_side)
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
      proxy_incoming_to(@client_side, 10240)
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
