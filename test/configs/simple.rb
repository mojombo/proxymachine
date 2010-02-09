LOGGER = Logger.new(File.new('/dev/null', 'w'))

proxy do |data|
  if data == 'a'
    { :remote => "localhost:9980" }
  elsif data == 'b'
    { :remote => "localhost:9981" }
  elsif data == 'c'
    { :remote => "localhost:9980", :data => 'ccc' }
  elsif data == 'd'
    { :close => 'ddd' }
  elsif data == 'e' * 2048
    { :noop => true }
  elsif data == 'e' * 2048 + 'f'
    { :remote => "localhost:9980" }
  elsif data == 'g'
    { :remote => "localhost:9980", :data => 'g2', :reply => 'g3-' }
  elsif data == 'connect reject'
    { :remote => "localhost:9989" }
  elsif data == 'inactivity'
    { :remote => "localhost:9980", :data => 'sleep 3', :inactivity_timeout => 1 }
  else
    { :close => true }
  end
end

ERROR_FILE = File.expand_path('../../proxy_error', __FILE__)

proxy_connect_error do |remote|
  File.open(ERROR_FILE, 'wb') { |fd| fd.write("connect error: #{remote}") }
end

proxy_inactivity_error do |remote|
  File.open(ERROR_FILE, 'wb') { |fd| fd.write("activity error: #{remote}") }
end
