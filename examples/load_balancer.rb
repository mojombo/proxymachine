require 'json'

# match server cookie, signon cookie?
# if server cookie found, connect (deal with error)
# if no cookie, lookup backends, apply statistical weight...



class BeeRouter

  @backends = {"1.smeg.com" => ["localhost:8081", "localhost:8080"], "2.smeg.com" => "localhost:8080"}
  
  def self.get_backend host

    be = @backends[host]
    if be then
      if be.class == String then
        { :remote => be }
      else
        {:remote => be[rand(be.size)]}
      end
    else
      { :noop => true }
    end
  end

  def self.remove_backend host
    @backends.each do |k,v|
      if v.instance_of?(Array) and v.size > 1
        v.delete(host)
      end
    end
  end
  
end


proxy do |data|
  # p data
  #data =~ %r{^Host\:([a-z]+)\n }
  #Host: bar.something.com:9999
  #puts data
  #puts "MATCH: " + $1
 # { :remote => "www.unsw.edu.au:80" }

  if data =~ %r{^Host:(.*)}
    name = $1
    BeeRouter.get_backend name.strip
  else
    { :noop => true }
  end

end


proxy_connect_error do |remote|
  puts "OHNOES! error connecting to #{remote}"
  puts "Now removing it"
  BeeRouter.remove_backend(remote)
end


