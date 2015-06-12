require 'helper'

class TestDecoder < Test::Unit::TestCase
  def setup
    @decrypter = stub('decrypter')
    @unserializer = stub('unserializer')
    @decoder = Keyrack::Decoder.new(@decrypter, @unserializer)
  end

  test "#decode" do
    @decrypter.expects(:decrypt).with('ciphertext', 'secret', 0, 0.500, 20.0).returns('foo')
    object = stub('object')
    @unserializer.expects(:parse).with('foo').returns(object)
    assert_equal object, @decoder.decode('ciphertext', 'secret')
  end
end
