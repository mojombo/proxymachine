# To try out the graceful exit via SIGQUIT, start up a proxymachine with this
# configuration, and run the following curl command a few times:
#     curl http://localhost:5432/ubuntu-releases/9.10/ubuntu-9.10-beta-alternate-amd64.iso \
#     -H "Host: mirrors.cat.pdx.edu" > /dev/null
# Then send a SIGQUIT to the process and stop the long downloads one by one.

proxy do |data|
  { :remote => "mirrors.cat.pdx.edu:80" }
end