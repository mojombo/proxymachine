require 'memcache'
require 'json'

# MemCache.new 'localhost:11211', :namespace => 'my_namespace'
# match server cookie, signon cookie?
# if server cookie found, connect (deal with error)
# if no cookie, lookup backends, apply statistical weight...

@log = Logger.new(STDOUT)

class BeeRouter

  def get_backend host
        backends = {"1.smeg.com" => ["www.unsw.edu.au:80", "news.com:80", "news.com:80"], "2.smeg.com" => "www.news.com:80"}
        be = backends[host]
    if be then
      if be.class == String then
        { :remote => be }
      else
        puts "hey 1"
        {:remote => be[rand(be.size)]}
      end
    else
      { :noop => true }
    end
  end
  
end


@bee_router = BeeRouter.new

proxy do |data|
  # p data
  #data =~ %r{^Host\:([a-z]+)\n }
  #Host: bar.something.com:9999
  #puts data
  #puts "MATCH: " + $1
 # { :remote => "www.unsw.edu.au:80" }

  if data =~ %r{^Host\:(.*)}
    name = $1
    @log.info( "Host name: #{name.strip == '2.smeg.com'}" )
    @bee_router.get_backend name.strip
  else
    { :noop => true }
  end
 
end


