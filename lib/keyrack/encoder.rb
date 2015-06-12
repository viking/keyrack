module Keyrack
  class Encoder
    DEFAULT_OPTIONS = { :maxmem => 0, :maxmemfrac => 0.125, :maxtime => 5.0 }

    def initialize(encrypter = Scrypty, serializer = JSON, options = DEFAULT_OPTIONS)
      @encrypter = encrypter
      @serializer = serializer
      @options = options
    end

    def encode(object, password)
      data = @serializer.generate(object)
      @encrypter.encrypt(data, password, @options[:maxmem],
                         @options[:maxmemfrac], @options[:maxtime])
    end
  end
end
