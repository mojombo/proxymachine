require 'json'

#
# This is an example of a weighted load balancer - showing failover using proxymachine (requires a patched proxy machine for failover to work.
#
# The weighted load balancer uses randomisation - stateless and simple. For a backend to have more weight, it can appear multiple times in the @backends map
# (this could be in memcached if other systems wanted to update this map)
#
class BeeRouter

  @backends = {"1.smeg.com" => ["localhost:9090", "localhost:8080"], "2.smeg.com" => ["localhost:8081"], "3.smeg.com" => ["localhost:8080"]}
  
  def self.get_backend host
    be = @backends[host]
    if be and be.instance_of?(Array)
        if be.size > 0
          be[rand(be.size)]
        end
    end
  end
  

  def self.remove_backend host
    result = false
    @backends.each do |k,v|
      if v.instance_of?(Array)
        if v.delete(host)
            result = v.size > 0
        end
      end
    end
    result
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
    backend = BeeRouter.get_backend name.strip
    if backend
      {:remote => backend }
    else
      {:close => true}
    end
  else
    { :noop => true }
  end

end


proxy_connect_error do |remote|
  puts "OHNOES! error connecting to #{remote}"
  puts "Now removing it"
  BeeRouter.remove_backend(remote) #the return value of this will decide if it will try again...
end


