ProxyMachine
============

By Tom Preston-Werner (tom@mojombo.com)


Description
-----------

ProxyMachine is a simple content aware (layer 7) TCP routing proxy built on
EventMachine that lets you configure the routing logic in Ruby.

If you need to proxy connections to different backend servers depending on the
contents of the transmission, then ProxyMachine will make your life easy!

The idea here is simple. For each client connection, start receiving data
chunks and placing them into a buffer. Each time a new chunk arrives, send the
buffer to a user specified block. The block's job is to parse the buffer to
determine where the connection should be proxied. If the buffer contains
enough data to make a determination, the block returns the address and port of
the correct backend server. If not, it can choose to do nothing and wait for
more data to arrive, close the connection, or close the connection after
sending custom data. Once the block returns an address, a connection to the
backend is made, the buffer is replayed to the backend, and the client and
backend connections are hooked up to form a transparent proxy. This
bidirectional proxy continues to exist until either the client or backend
close the connection.

ProxyMachine was developed for GitHub's federated architecture and is successfully used in production to proxy millions of requests every day. The performance and memory profile have both proven to be excellent.


Installation
------------

    $ gem install proxymachine -s http://gemcutter.org


Running
-------

    Usage:
      proxymachine -c <config file> [-h <host>] [-p <port>]

    Options:
      -c, --config CONFIG              Configuration file
      -h, --host HOST                  Hostname to bind. Default 0.0.0.0
      -p, --port PORT                  Port to listen on. Default 5432


Signals
-------

    QUIT - Graceful shutdown. Stop accepting connections immediately and
           wait as long as necessary for all connections to close.

    TERM - Fast shutdown. Stop accepting connections immediately and wait
           up to 10 seconds for connections to close before forcing
           termination.

    INT  - Same as TERM


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
    # connection.
    proxy do |data|
      if data =~ %r{^....git-upload-pack /([\w\.\-]+)/[\w\.\-]+\000host=\w+\000}
        name = $1
        { :remote => GitRouter.lookup(name) }
      else
        { :noop => true }
      end
    end


Valid return values
-------------------

`{ :remote => String }` - String is the host:port of the backend server that will be proxied.  
`{ :remote => String, :data => String }` - Same as above, but send the given data instead.  
`{ :noop => true }` - Do nothing.  
`{ :close => true }` - Close the connection.  
`{ :close => String }` - Close the connection after sending the String.  


Contribute
----------

If you'd like to hack on ProxyMachine, start by forking my repo on GitHub:

http://github.com/mojombo/proxymachine

To get all of the dependencies, install the gem first. The best way to get
your changes merged back into core is as follows:

1. Clone down your fork
1. Create a topic branch to contain your change
1. Hack away
1. Add tests and make sure everything still passes by running `rake`
1. If you are adding new functionality, document it in the README.md
1. Do not change the version number, I will do that on my end
1. If necessary, rebase your commits into logical chunks, without errors
1. Push the branch up to GitHub
1. Send me (mojombo) a pull request for your branch


Copyright
---------

Copyright (c) 2009 Tom Preston-Werner. See LICENSE for details.