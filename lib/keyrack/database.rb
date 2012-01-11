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
      if hash.has_key?(site)
        site_entry = hash[site]
        if site_entry.is_a?(Array)
          # Multiple entries for this site
          user_entry = site_entry.detect { |e| e[:username] == username }
          if user_entry
            # Update existing entry
            user_entry[:password] = password
          else
            # Add new entry
            site_entry.push({:username => username, :password => password})
          end
        elsif site_entry[:username] == username
          # Update existing entry
          site_entry[:password] = password
        else
          # Convert single entry into an array, then add new entry
          hash[site] = [site_entry, {:username => username, :password => password}]
        end
      else
        hash[site] = { :username => username, :password => password }
      end
      @dirty = true
    end

    def get(*args)
      options = args.last.is_a?(Hash) ? args.pop : {}
      site, username = args

      site_entry = (options[:group] ? @data[options[:group]] : @data)[site]
      if username
        if site_entry.is_a?(Array)
          site_entry.find { |e| e[:username] == username }
        elsif site_entry[:username] == username
          site_entry
        else
          nil
        end
      else
        site_entry
      end
    end

    def sites(options = {})
      hash = options[:group] ? @data[options[:group]] : @data
      if hash
        hash.keys.select do |key|
          val = hash[key]
          val.is_a?(Array) || (val.is_a?(Hash) && val.has_key?(:username))
        end.sort
      else
        # new groups are empty
        []
      end
    end

    def groups
      @data.keys.reject do |key|
        val = @data[key]
        val.is_a?(Array) || (val.is_a?(Hash) && val.has_key?(:username))
      end.sort
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

    def delete(site, username, options = {})
      hash = options[:group] ? @data[options[:group]] : @data
      site_entry = hash[site]

      if site_entry.is_a?(Array)
        site_entry.each_with_index do |entry, i|
          if entry[:username] == username
            case site_entry.length
            when 2
              site_entry.delete_at(i)
              hash[site] = site_entry[0]
            when 1
              hash.delete(site)
            else
              site_entry.delete_at(i)
            end

            @dirty = true
            break
          end
        end
      elsif site_entry[:username] == username
        hash.delete(site)
        @dirty = true
      end
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
