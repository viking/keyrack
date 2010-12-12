require 'helper'

class Keymaster
  class TestStore < Test::Unit::TestCase
    def test_get
      assert_equal Store::Filesystem, Store[:filesystem]
    end
  end
end
