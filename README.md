ProxyMachine
============

By Tom Preston-Werner (tom@mojombo.com)


Description
-----------

ProxyMachine is a simple TCP routing proxy built on EventMachine that lets you
configure the routing logic in Ruby.


Example basic config file
-------------------------

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


Copyright
---------

Copyright (c) 2009 Tom Preston-Werner. See LICENSE for details.