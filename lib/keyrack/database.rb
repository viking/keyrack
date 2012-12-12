module Keyrack
  class Database
    DEFAULT_OPTIONS = { :maxmem => 0, :maxmemfrac => 0.125, :maxtime => 5.0 }
    VERSION = 3

    def initialize(key, store, encrypt_options = {}, decrypt_options = {})
      @encrypt_options = DEFAULT_OPTIONS.merge(encrypt_options)
      @decrypt_options = DEFAULT_OPTIONS.merge(decrypt_options)
      @store = store
      @database = decrypt(key)
      @dirty = false
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

    def save(key)
      @store.write(Scrypty.encrypt(@database.to_yaml, key,
        *@encrypt_options.values_at(:maxmem, :maxmemfrac, :maxtime)))
      @dirty = false
    end

    private

    def decrypt(key)
      data = @store.read
      if data
        str = Scrypty.decrypt(data, key,
          *@decrypt_options.values_at(:maxmem, :maxmemfrac, :maxtime))
        YAML.load(str)
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
      group.after_site_added do |affected_group, added_site|
        @dirty = true
      end
      group.after_site_removed do |affected_group, removed_site|
        @dirty = true
      end
      group.after_login_added do |affected_group, affected_site, username, password|
        @dirty = true
      end
      group.after_login_removed do |affected_group, affected_site, username, password|
        @dirty = true
      end
      group.after_username_changed do |affected_group, affected_site, old_username, new_username|
        @dirty = true
      end
      group.after_password_changed do |affected_group, affected_site, username, old_password, new_password|
        @dirty = true
      end
      group.after_group_added do |affected_group, added_group|
        @dirty = true
        add_group_hooks_for(added_group)
      end
      group.after_group_removed do |affected_group, removed_group|
        @dirty = true
      end
    end
  end
end
