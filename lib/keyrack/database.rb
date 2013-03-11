module Keyrack
  class Database
    DEFAULT_ENCRYPT_OPTIONS = { :maxmem => 0, :maxmemfrac => 0.125, :maxtime => 5.0 }
    DEFAULT_DECRYPT_OPTIONS = { :maxmem => 0, :maxmemfrac => 0.250, :maxtime => 10.0 }
    VERSION = 4

    def initialize(password, store, encrypt_options = {}, decrypt_options = {})
      @dirty = false
      @encrypt_options = DEFAULT_ENCRYPT_OPTIONS.merge(encrypt_options)
      @decrypt_options = DEFAULT_DECRYPT_OPTIONS.merge(decrypt_options)
      @store = store
      @password = password_hash(password)
      @database = decrypt(password)
      setup_hooks
    end

    def version
      @database['version']
    end

    def top_group
      @database['groups']['top']
    end

    def dirty?
      @dirty
    end

    def save(password)
      if password_hash(password) == @password
        @store.write(Scrypty.encrypt(@database.to_yaml, password,
          *@encrypt_options.values_at(:maxmem, :maxmemfrac, :maxtime)))
        @dirty = false
        true
      else
        false
      end
    end

    def change_password(current_password, new_password)
      if password_hash(current_password) == @password
        @password = password_hash(new_password)
        true
      else
        false
      end
    end

    private

    def password_hash(password)
      # Avoid storing the database password as-is in memory, but don't
      # spend too much effort obfuscating it.
      sha256 = Digest::SHA256.new
      sha256.digest "#{password}-#{$$}"
    end

    def decrypt(password)
      data = @store.read
      if data
        str = Scrypty.decrypt(data, password,
          *@decrypt_options.values_at(:maxmem, :maxmemfrac, :maxtime))
        hash = YAML.load(str)
        migrated_hash = Migrator.run(hash)
        if !migrated_hash.equal?(hash)
          hash = migrated_hash
          @dirty = true
        end

        top = Group.new
        top.load(hash['groups']['top'])
        hash['groups']['top'] = top

        hash
      else
        {'groups' => {'top' => Group.new('top')}, 'version' => VERSION}
      end
    end

    def setup_hooks
      @database['groups'].each_pair do |group_name, group|
        add_group_hooks_for(group)
      end
    end

    def add_group_hooks_for(group)
      group.after_event do |event|
        @dirty = true
      end
    end
  end
end
