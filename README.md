ProxyMachine
============

By Tom Preston-Werner (tom@mojombo.com)


Description
-----------

ProxyMachine is a simple content aware TCP routing proxy built on EventMachine
that lets you configure the routing logic in Ruby.

The idea here is simple. For each client connection, start receiving data
chunks and placing them into a buffer. Each time a new chunk arrives, send the
buffer to a user specified block. The block's job is to parse the buffer to
determine where the connection should proxied. If the buffer contains enough
data to make a determination, the block returns the address and port of the
correct backend server. If not, it can choose to either do nothing and wait
for more data to arrive, or close the connection. Once the block returns an
address, a connection to the backend is made, the buffer is replayed to the
backend, and the client and backend connections are hooked up to form a
straight proxy. This bidirectional proxy continues to exist until with the
client or backend close the connection.


Running
-------

    Usage:
      proxymachine -c <config file> [-h <host>] [-p <port>]

    Options:
      -c, --config CONFIG              Configuration file
      -h, --host HOST                  Hostname to bind. Default 0.0.0.0
      -p, --port PORT                  Port to listen on. Default 5432


Example routing config file
---------------------------

    class GitRouter
      # Look at the routing table and return the correct address for +name+
      # Returns "<host>:<port>" e.g. "ae8f31c.example.com:9418"
      def self.lookup(name)
        ...
      end
    end

    # Perform content-aware routing based on the stream data. Here, the
    # header information from the Git protocol is parsed to find the 
    # username and a lookup routine is run on the name to find the correct
    # backend server. If no match can be made yet, do nothing with the
    # connection yet.
    proxy do |data|
      if data =~ %r{^....git-upload-pack /([\w\.\-]+)/[\w\.\-]+\000host=\w+\000}
        name = $1
        GitRouter.lookup(name)
      else
        :noop
      end
    end


Copyright
---------

Copyright (c) 2009 Tom Preston-Werner. See LICENSE for details.