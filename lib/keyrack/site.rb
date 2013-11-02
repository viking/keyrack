module Keyrack
  class Site
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
      else
        hash = {
          'name' => args[0],
          'username' => args[1],
          'password' => args[2]
        }
      end
      @attributes = hash

      @event_hooks = []
    end

    def change_attribute(name, value)
      event = Event.new(self, 'change')
      event.attribute_name = name
      event.previous_value = @attributes[name]
      event.new_value = value

      @attributes[name] = value
      trigger(event)
    end

    def name
      @attributes['name']
    end

    def name=(name)
      change_attribute('name', name)
    end

    def username
      @attributes['username']
    end

    def username=(username)
      change_attribute('username', username)
    end

    def password
      @attributes['password']
    end

    def password=(password)
      change_attribute('password', password)
    end

    def after_event(&block)
      @event_hooks << block
    end

    def ==(other)
      if other.instance_of?(Site)
        other.name == name && other.username == username
      else
        super
      end
    end

    def to_h
      @attributes.clone
    end

    private

    def trigger(event)
      @event_hooks.each do |block|
        block.call(event)
      end
    end
  end
end
