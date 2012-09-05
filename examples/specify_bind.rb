proxy do |data|
  return if not data.match(/([^:]+):?(\d*)/)
  bind_addr=$1.to_s.strip
  bind_port=$2.to_s.strip
  # p datai
  { :remote => "127.0.0.1:31337",
    :local_bind =>"#{bind_addr}:#{bind_port}"
  }
end