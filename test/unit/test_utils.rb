require 'helper'

class TestUtils < Test::Unit::TestCase
  def test_generate_password
    result = Keyrack::Utils.generate_password
    assert_match /^[!-~]{8}$/, result
  end
end
