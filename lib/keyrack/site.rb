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
    end

    def password_for(username)
      if !logins.has_key?(username)
        raise SiteError, "username doesn't exist"
      end
      logins[username]
    end

    def change_password(username, password)
      if !logins.has_key?(username)
        raise SiteError, "username doesn't exist"
      end
      logins[username] = password
    end

    def remove_login(username)
      if !logins.has_key?(username)
        raise SiteError, "username doesn't exist"
      end
      logins.delete(username)
    end
  end
end
