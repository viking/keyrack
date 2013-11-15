module Keyrack
  class Group
    def initialize(arg = nil)
      @attributes = {}

      case arg
      when String
        @attributes['name'] = arg
        @attributes['sites'] = []
        @attributes['groups'] = {}
      when Hash
        load(arg)
      when nil
        @uninitialized = true
      end

      @after_event = []
    end

    def load(hash)
      @loading = true

      if !hash.has_key?('name')
        raise ArgumentError, "hash is missing the 'name' key"
      end
      if !hash['name'].is_a?(String)
        raise ArgumentError, "name is not a String"
      end
      @attributes['name'] = hash['name']

      if !hash.has_key?('sites')
        raise ArgumentError, "hash is missing the 'sites' key"
      end
      if !hash['sites'].is_a?(Array)
        raise ArgumentError, "sites is not an Array"
      end

      if !hash.has_key?('groups')
        raise ArgumentError, "hash is missing the 'groups' key"
      end
      if !hash['groups'].is_a?(Hash)
        raise ArgumentError, "groups is not a Hash"
      end

      @attributes['sites'] = []
      hash['sites'].each_with_index do |site_hash, site_index|
        if !site_hash.is_a?(Hash)
          raise ArgumentError, "site #{site_index} is not a Hash"
        end

        begin
          site = Site.new(site_hash)
          add_site_without_callbacks(site)
        rescue SiteError => e
          raise ArgumentError, "site #{site_index} is not valid: #{e.message}"
        end
      end

      @attributes['groups'] = {}
      hash['groups'].each_pair do |group_name, group_hash|
        if !group_name.is_a?(String)
          raise ArgumentError, "group key is not a String"
        end
        if !group_hash.is_a?(Hash)
          raise ArgumentError, "group value for #{group_name.inspect} is not a Hash"
        end

        begin
          group = Group.new(group_hash)
          add_group_without_callbacks(group)
        rescue ArgumentError => e
          raise ArgumentError, "group #{group_name.inspect} is not valid: #{e.message}"
        end

        if group.name != group_name
          raise ArgumentError, "group name mismatch: #{group_name.inspect} != #{group.name.inspect}"
        end
      end

      @loading = false
      @uninitialized = false
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

    def sites
      @attributes['sites']
    end

    def groups
      @attributes['groups']
    end

    def add_site(site)
      raise "add_site is not allowed until Group is initialized" if @uninitialized && !@loading
      add_site_without_callbacks(site)

      event = Event.new(self, 'add')
      event.collection_name = 'sites'
      event.object = site
      trigger(event)
    end

    def site(index)
      sites[index]
    end

    def remove_site(site)
      raise "remove_site is not allowed until Group is initialized" if @uninitialized && !@loading
      index = sites.index(site)
      if index.nil?
        raise GroupError, "site doesn't exist"
      end
      site = sites.delete_at(index)

      event = Event.new(self, 'remove')
      event.collection_name = 'sites'
      event.object = site
      trigger(event)
    end

    def add_group(group)
      raise "add_group is not allowed until Group is initialized" if @uninitialized && !@loading
      add_group_without_callbacks(group)

      event = Event.new(self, 'add')
      event.collection_name = 'groups'
      event.object = group
      trigger(event)
    end

    def remove_group(group_name)
      raise "remove_group is not allowed until Group is initialized" if @uninitialized && !@loading
      if !groups.has_key?(group_name)
        raise GroupError, "group doesn't exist"
      end
      group = groups.delete(group_name)

      event = Event.new(self, 'remove')
      event.collection_name = 'groups'
      event.object = group
      trigger(event)
    end

    def group(group_name)
      groups[group_name]
    end

    def group_names
      groups.keys
    end

    def after_event(&block)
      @after_event << block
    end

    def to_h
      hash = @attributes.dup
      hash['sites'] = hash['sites'].collect(&:to_h)
      hash['groups'] = hash['groups'].inject({}) do |hash2, (key, value)|
        hash2[key] = value.to_h
        hash2
      end
      hash
    end

    private

    def add_site_without_callbacks(site)
      if !site.is_a?(Site)
        raise GroupError, "site is not a Site"
      end
      if sites.include?(site)
        raise GroupError,
          "site (#{site.name.inspect}, #{site.username.inspect}) already exists"
      end

      index = sites.length
      sites.each_with_index do |other, i|
        if other.name > site.name ||
              (other.name == site.name && other.username > site.username)
          index = i
          break
        end
      end
      sites.insert(index, site)

      add_site_hooks_for(site)
    end

    def add_group_without_callbacks(group)
      if !group.is_a?(Group)
        raise GroupError, "group is not a Group"
      end
      if groups.has_key?(group.name)
        raise GroupError, "group already exists"
      end

      # wasteful but easy hash ordering
      groups[group.name] = group
      keys = groups.keys.sort!
      new_groups = keys.inject({}) do |hsh, key|
        hsh[key] = groups[key]
        hsh
      end
      @attributes['groups'] = new_groups

      add_group_hooks_for(group)
    end

    def trigger(event)
      @after_event.each do |block|
        block.call(event)
      end
    end

    def add_site_hooks_for(site)
      site.after_event do |site_event|
        trigger(Event.new(self, 'change', site_event))
      end
    end

    def add_group_hooks_for(group)
      group.after_event do |group_event|
        if group_event.name == 'change' && group_event.attribute_name == 'name'
          key, value = groups.find { |(k, v)| v.equal?(group) }
          if key
            groups[group.name] = groups.delete(key)
          end
        end

        trigger(Event.new(self, 'change', group_event))
      end
    end
  end
end
