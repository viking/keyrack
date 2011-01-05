module Keyrack
  class Database
    def initialize(key, iv, store)
      @key = key
      @iv = iv
      @store = store
      @data = decrypt
      @dirty = false
    end

    def add(site, username, password, options = {})
      hash = options[:group] ? @data[options[:group]] ||= {} : @data
      hash[site] = { :username => username, :password => password }
      @dirty = true
    end

    def get(site, options = {})
      (options[:group] ? @data[options[:group]] : @data)[site]
    end

    def sites(options = {})
      hash = options[:group] ? @data[options[:group]] : @data
      if hash
        hash.keys.select { |k| hash[k].keys.include?(:username) }.sort
      else
        # new groups are empty
        []
      end
    end

    def groups
      @data.keys.reject { |k| @data[k].keys.include?(:username) }.sort
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

    def delete(site, options = {})
      hash = options[:group] ? @data[options[:group]] : @data
      hash.delete(site)
      @dirty = true
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
