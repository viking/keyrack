module Keyrack
  class Decoder
    DEFAULT_OPTIONS = { :maxmem => 0, :maxmemfrac => 0.500, :maxtime => 20.0 }

    def initialize(decrypter = Scrypty, unserializer = JSON, options = DEFAULT_OPTIONS)
      @decrypter = decrypter
      @unserializer = unserializer
      @options = options
    end

    def decode(ciphertext, password)
      data = @decrypter.decrypt(ciphertext, password, @options[:maxmem],
                                @options[:maxmemfrac], @options[:maxtime])
      @unserializer.parse(data)
    end
  end
end
