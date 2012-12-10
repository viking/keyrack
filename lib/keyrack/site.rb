module Keyrack
  class Site < Hash
    def initialize(arg)
      case arg
      when String
        self[:name] = arg
        self[:logins] = {}
      when Hash
        if !arg.has_key?(:name)
          raise ArgumentError, "hash is missing the :name key"
        end
        if !arg[:name].is_a?(String)
          raise ArgumentError, "name is not a String"
        end
        if !arg.has_key?(:logins)
          raise ArgumentError, "hash is missing the :logins key"
        end
        if !arg[:logins].is_a?(Hash)
          raise ArgumentError, "logins is not a Hash"
        end
        if arg[:logins].any? { |(k, v)| !k.is_a?(String) || !v.is_a?(String) }
          raise ArgumentError, "logins hash is not made up of strings"
        end
        update(arg)
      end

      @after_add = []
      @after_change = []
      @after_remove = []
    end

    def name
      self[:name]
    end

    def logins
      self[:logins]
    end

    def usernames
      logins.keys
    end

    def add_login(username, password)
      if logins.has_key?(username)
        raise SiteError, "username already exists"
      end
      logins[username] = password
      @after_add.each do |block|
        block.call(username, password)
      end
    end

    def password_for(username)
      if !logins.has_key?(username)
        raise SiteError, "username doesn't exist"
      end
      logins[username]
    end

    def change_password(username, new_password)
      if !logins.has_key?(username)
        raise SiteError, "username doesn't exist"
      end
      old_password = logins[username]
      logins[username] = new_password
      @after_change.each do |block|
        block.call(username, old_password, new_password)
      end
    end

    def remove_login(username)
      if !logins.has_key?(username)
        raise SiteError, "username doesn't exist"
      end
      password = logins.delete(username)
      @after_remove.each do |block|
        block.call(username, password)
      end
    end

    def after_add(&block)
      @after_add << block
    end

    def after_change(&block)
      @after_change << block
    end

    def after_remove(&block)
      @after_remove << block
    end
  end
end
