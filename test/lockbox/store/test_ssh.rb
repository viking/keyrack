require 'helper'

module Lockbox
  module Store
    class TestSSH < Test::Unit::TestCase
      def test_read
        store = SSH.new(:host => 'example.com', :user => 'dude', :path => 'foo.txt')
        Net::SCP.expects(:download!).with("example.com", "dude", "foo.txt").returns("foo")
        assert_equal "foo", store.read
      end

      def test_write
        store = SSH.new(:host => 'example.com', :user => 'dude', :path => 'foo.txt')
        Net::SCP.expects(:upload!).with do |host, user, local, remote|
          host == 'example.com' && user == 'dude' && local.is_a?(StringIO) &&
            local.read == "foo" && remote == "foo.txt"
        end
        store.write("foo")
      end

      def test_read_returns_nil_for_non_existant_file
        store = SSH.new(:host => 'example.com', :user => 'dude', :path => 'foo.txt')
        Net::SCP.expects(:download!).with("example.com", "dude", "foo.txt").raises(Net::SCP::Error)
        assert_nil store.read
      end
    end
  end
end
