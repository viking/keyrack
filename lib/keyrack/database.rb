module Keyrack
  class Database
    def initialize(config)
      store_config = config['store'].dup
      @store = Store[store_config.delete('type')].new(store_config)
      key_path = File.expand_path(config['key'])
      @key = OpenSSL::PKey::RSA.new(File.read(key_path), config['password'])
      @data = decrypt
      @dirty = false
    end

    def add(site, username, password)
      @data[site] = { :username => username, :password => password }
      @dirty = true
    end

    def get(site)
      @data[site]
    end

    def sites
      @data.keys
    end

    def dirty?
      @dirty
    end

    def save
      @store.write(@key.public_encrypt(Marshal.dump(@data)))
      @dirty = false
    end

    private
      def decrypt
        data = @store.read
        data ? Marshal.load(@key.private_decrypt(data)) : {}
      end
  end
end
