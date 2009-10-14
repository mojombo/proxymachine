# This is a config file for ProxyMachine. It pulls the username out of
# the Git stream and can proxy to different locations based on that value
# Run with `proxymachine -c examples/git.rb`

class GitRouter
  # Look at the routing table and return the correct address for +name+
  # Returns "<host>:<port>" e.g. "ae8f31c.example.com:9418"
  def self.lookup(name)
    LOGGER.info "Proxying for user #{name}"
    "localhost:9418"
  end
end

# Perform content-aware routing based on the stream data. Here, the
# header information from the Git protocol is parsed to find the
# username and a lookup routine is run on the name to find the correct
# backend server. If no match can be made yet, do nothing with the
# connection yet.
proxy do |data|
  if data =~ %r{^....git-upload-pack /([\w\.\-]+)/[\w\.\-]+\000host=(.+)\000}
    name, host = $1, $2
    { :remote => GitRouter.lookup(name) }
  else
    { :noop => true }
  end
end