require 'helper'

class TestEncoder < Test::Unit::TestCase
  def setup
    @encrypter = stub('encrypter')
    @serializer = stub('serializer')
    @encoder = Keyrack::Encoder.new(@encrypter, @serializer)
  end

  test "#encode" do
    object = stub('object')
    @serializer.expects(:generate).with(object).returns('foo')
    @encrypter.expects(:encrypt).with('foo', 'secret', 0, 0.125, 5.0).returns('cipher')
    assert_equal 'cipher', @encoder.encode(object, 'secret')
  end
end
