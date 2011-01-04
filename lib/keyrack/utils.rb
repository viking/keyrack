module Keyrack
  module Utils
    def self.generate_password
      result = "        "
      result.length.times do |i|
        result[i] = (33 + rand(94)).chr
      end
      result
    end

    def self.generate_rsa_key(password)
      rsa = OpenSSL::PKey::RSA.new(4096)
      cipher = OpenSSL::Cipher::Cipher.new('des3')
      [rsa, rsa.to_pem(cipher, password)]
    end

    def self.generate_aes_key
      SecureRandom.base64(128)[0..127]
    end

    def self.open_rsa_key(path, password)
      OpenSSL::PKey::RSA.new(File.read(path), password)
    end

    def self.open_aes_data(path, rsa_key)
      Marshal.load(rsa_key.private_decrypt(File.read(path)))
    end
  end
end
