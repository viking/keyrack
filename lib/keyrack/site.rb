module Keyrack
  class Site < Hash
    def initialize(name)
      self[:name] = name
      self[:logins] = {}
    end

    def name
      self[:name]
    end

    def logins
      self[:logins]
    end

    def add_login(username, password)
      if logins.has_key?(username)
        raise SiteError, "username already exists"
      end
      logins[username] = password
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
