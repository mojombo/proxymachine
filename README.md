ProxyMachine
============

By Tom Preston-Werner (tom@mojombo.com)


Description
-----------

ProxyMachine is a simple content aware TCP routing proxy built on EventMachine
that lets you configure the routing logic in Ruby.


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