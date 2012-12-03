require 'helper'

module Keyrack
  class TestUtils < Test::Unit::TestCase
    def test_generate_password
      result = Utils.generate_password
      assert_match /^[!-~]{8}$/, result
    end

    def test_generate_rsa_key
      rsa = mock('rsa')
      OpenSSL::PKey::RSA.expects(:new).with(4096).returns(rsa)
      cipher = mock('cipher')
      OpenSSL::Cipher::Cipher.expects(:new).with('des3').returns(cipher)
      rsa.expects(:to_pem).with(cipher, 'secret').returns('private key')

      assert_equal([rsa, 'private key'], Utils.generate_rsa_key('secret'))
    end

    def test_generate_aes_key
      SecureRandom.expects(:base64).with(128).returns("x" * 172)
      result = Utils.generate_aes_key
      assert_equal 128, result.length
    end

    def test_open_rsa_key
      rsa_path = fixture_path('id_rsa')
      rsa = mock('rsa')
      OpenSSL::PKey::RSA.expects(:new).with(File.read(rsa_path), 'secret').returns(rsa)
      assert_equal(rsa, Utils.open_rsa_key(rsa_path, 'secret'))
    end

    def test_open_aes_data
      aes_path = fixture_path('aes')
      aes = {'key' => '12345', 'iv' => '54321'}
      rsa = mock('rsa')
      rsa.expects(:private_decrypt).with(File.read(aes_path)).returns(Marshal.dump(aes))
      assert_equal(aes, Utils.open_aes_data(aes_path, rsa))
    end
  end
end
