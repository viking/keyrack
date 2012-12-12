module Keyrack
  class Site < Hash
    def initialize(arg)
      case arg
      when String
        self['name'] = arg
        self['logins'] = {}
      when Hash
        if !arg.has_key?('name')
          raise ArgumentError, "hash is missing the 'name' key"
        end
        if !arg['name'].is_a?(String)
          raise ArgumentError, "name is not a String"
        end
        if !arg.has_key?('logins')
          raise ArgumentError, "hash is missing the 'logins' key"
        end
        if !arg['logins'].is_a?(Hash)
          raise ArgumentError, "logins is not a Hash"
        end
        if arg['logins'].any? { |(k, v)| !k.is_a?(String) || !v.is_a?(String) }
          raise ArgumentError, "logins hash is not made up of strings"
        end
        self.update(arg)
      end

      @after_login_added = []
      @after_username_changed = []
      @after_password_changed = []
      @after_login_removed = []
    end

    def name
      self['name']
    end

    def logins
      self['logins']
    end

    def usernames
      logins.keys
    end

    def add_login(username, password)
      if logins.has_key?(username)
        raise SiteError, "username already exists"
      end
      logins[username] = password

      @after_login_added.each do |block|
        block.call(self, username, password)
      end
    end

    def password_for(username)
      if !logins.has_key?(username)
        raise SiteError, "username doesn't exist"
      end
      logins[username]
    end

    def change_username(old_username, new_username)
      if !logins.has_key?(old_username)
        raise SiteError, "username doesn't exist"
      end
      logins[new_username] = logins.delete(old_username)

      @after_username_changed.each do |block|
        block.call(self, old_username, new_username)
      end
    end

    def change_password(username, new_password)
      if !logins.has_key?(username)
        raise SiteError, "username doesn't exist"
      end
      old_password = logins[username]
      logins[username] = new_password

      @after_password_changed.each do |block|
        block.call(self, username, old_password, new_password)
      end
    end

    def remove_login(username)
      if !logins.has_key?(username)
        raise SiteError, "username doesn't exist"
      end
      password = logins.delete(username)

      @after_login_removed.each do |block|
        block.call(self, username, password)
      end
    end

    def after_login_added(&block)
      @after_login_added << block
    end

    def after_username_changed(&block)
      @after_username_changed << block
    end

    def after_password_changed(&block)
      @after_password_changed << block
    end

    def after_login_removed(&block)
      @after_login_removed << block
    end

    def encode_with(coder)
      coder.represent_map(nil, self)
    end
  end
end
