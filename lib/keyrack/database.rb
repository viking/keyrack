module Keyrack
  class Database
    def initialize(key, iv, store)
      @key = key
      @iv = iv
      @store = store
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
      cipher = OpenSSL::Cipher::Cipher.new("AES-128-CBC")
      cipher.encrypt; cipher.key = @key; cipher.iv = @iv
      @store.write(cipher.update(Marshal.dump(@data)) + cipher.final)
      @dirty = false
    end

    private
      def decrypt
        data = @store.read
        if data
          cipher = OpenSSL::Cipher::Cipher.new("AES-128-CBC")
          cipher.decrypt; cipher.key = @key; cipher.iv = @iv
          Marshal.load(cipher.update(data) + cipher.final)
        else
          {}
        end
      end
  end
end
