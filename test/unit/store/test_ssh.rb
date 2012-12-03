require 'helper'

class TestSSH < Test::Unit::TestCase
  def test_read
    store = Keyrack::Store::SSH.new('host' => 'example.com', 'user' => 'dude', 'port' => 22, 'path' => 'foo.txt')
    scp = mock('scp session')
    scp.expects(:download!).with("foo.txt").returns("foo")
    session = mock('ssh session', :scp => scp)
    Net::SSH.expects(:start).with('example.com', 'dude', :port => 22).yields(session)
    assert_equal "foo", store.read
  end

  def test_write
    store = Keyrack::Store::SSH.new('host' => 'example.com', 'user' => 'dude', 'path' => 'foo.txt')
    scp = mock('scp session')
    session = mock('ssh session', :scp => scp)
    Net::SSH.expects(:start).with('example.com', 'dude', :port => 22).yields(session)
    scp.expects(:upload!).with do |local, remote|
      local.is_a?(StringIO) && local.read == "foo" && remote == "foo.txt"
    end
    store.write("foo")
  end

  def test_read_returns_nil_for_non_existant_file
    store = Keyrack::Store::SSH.new('host' => 'example.com', 'user' => 'dude', 'port' => 22, 'path' => 'foo.txt')
    scp = mock('scp session')
    scp.expects(:download!).with("foo.txt").raises(Net::SCP::Error)
    session = mock('ssh session', :scp => scp)
    Net::SSH.expects(:start).with('example.com', 'dude', :port => 22).yields(session)
    assert_nil store.read
  end
end
