require 'helper'

class TestStore < Test::Unit::TestCase
  def test_get_filesystem
    assert_equal Keyrack::Store::Filesystem, Keyrack::Store[:filesystem]
    assert_equal Keyrack::Store::Filesystem, Keyrack::Store['filesystem']
  end

  def test_get_ssh
    assert_equal Keyrack::Store::SSH, Keyrack::Store[:ssh]
    assert_equal Keyrack::Store::SSH, Keyrack::Store['ssh']
  end
end
