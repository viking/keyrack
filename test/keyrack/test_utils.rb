require 'helper'

module Keyrack
  class TestUtils < Test::Unit::TestCase
    def test_generate_password
      result = Utils.generate_password
      assert_match result, /^[!-~]{8}$/
    end
  end
end
