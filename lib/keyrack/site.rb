module Keyrack
  class Site < Hash
    def initialize(*args)
      if args[0].is_a?(Hash)
        hash = args[0]
        if !hash.has_key?('name')
          raise ArgumentError, "hash is missing the 'name' key"
        end
        if !hash['name'].is_a?(String)
          raise ArgumentError, "name is not a String"
        end
        if !hash.has_key?('username')
          raise ArgumentError, "hash is missing the 'username' key"
        end
        if !hash['username'].is_a?(String)
          raise ArgumentError, "name is not a String"
        end
        if !hash.has_key?('password')
          raise ArgumentError, "hash is missing the 'password' key"
        end
        if !hash['password'].is_a?(String)
          raise ArgumentError, "name is not a String"
        end
        self.update(hash)
      else
        self['name'] = args[0]
        self['username'] = args[1]
        self['password'] = args[2]
      end

      @after_username_changed = []
      @after_password_changed = []
    end

    def name
      self['name']
    end

    def username
      self['username']
    end

    def username=(username)
      self['username'] = username

      @after_username_changed.each do |block|
        block.call(self)
      end
    end

    def password
      self['password']
    end

    def password=(password)
      self['password'] = password

      @after_password_changed.each do |block|
        block.call(self)
      end
    end

    def after_username_changed(&block)
      @after_username_changed << block
    end

    def after_password_changed(&block)
      @after_password_changed << block
    end

    def encode_with(coder)
      coder.represent_map(nil, self)
    end

    def ==(other)
      if other.instance_of?(Site)
        other.name == name && other.username == username
      else
        super
      end
    end
  end
end
