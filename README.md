ProxyMachine
============

By Tom Preston-Werner (tom@mojombo.com)


Description
-----------

ProxyMachine is a simple TCP routing proxy built on EventMachine that lets you
configure the routing logic in Ruby.


Example hostname routing config file
------------------------------------

    # Proxy to a backend server based on hostname. In this example
    # hostnames that start with the letters a-m, and hostnames that
    # start with n-z must be proxied to different backends. Hostnames
    # that do not start with the letters a-z are to be closed.
    proxy do |host, port, data|
      if hostname =~ /^[a-m]/
        "10.0.0.100:5000"
      elsif hostname =~ /^[n-z]/
        "10.0.0.101:5000"
      else
        :close
      end
    end


Example content aware routing config file
-----------------------------------

    class GitRouter
      # Look at the routing table and return the correct IP for +name+
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
    proxy do |host, port, data|
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