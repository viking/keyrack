require 'helper'

module Keyrack
  class TestStore < Test::Unit::TestCase
    def test_get_filesystem
      assert_equal Store::Filesystem, Store[:filesystem]
      assert_equal Store::Filesystem, Store['filesystem']
    end

    def test_get_ssh
      assert_equal Store::SSH, Store[:ssh]
      assert_equal Store::SSH, Store['ssh']
    end
  end
end
