require 'test_helper'

def assert_proxy(host, port, send, recv)
  sock = TCPSocket.new(host, port)
  sock.write(send)
  assert_equal recv, sock.read
  sock.close
end

class ProxymachineTest < Test::Unit::TestCase
  should "handle simple routing" do
    assert_proxy('localhost', 9990, 'a', '9980:a')
    assert_proxy('localhost', 9990, 'b', '9981:b')
  end

  should "handle connection closing" do
    sock = TCPSocket.new('localhost', 9990)
    sock.write('xxx')
    assert_equal nil, sock.read(1)
    sock.close
  end

  should "handle rewrite routing" do
    assert_proxy('localhost', 9990, 'c', '9980:ccc')
  end

  should "handle rewrite closing" do
    assert_proxy('localhost', 9990, 'd', 'ddd')
  end

  should "handle data plus reply" do
    assert_proxy('localhost', 9990, 'g', 'g3-9980:g2')
  end

  should "handle noop" do
    sock = TCPSocket.new('localhost', 9990)
    sock.write('e' * 2048)
    sock.flush
    sock.write('f')
    assert_equal '9980:' + 'e' * 2048 + 'f', sock.read
    sock.close
  end
end
