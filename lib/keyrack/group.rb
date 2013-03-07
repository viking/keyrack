module Keyrack
  class Group < Hash
    def initialize(arg = nil)
      @after_site_added = []
      @after_site_removed = []
      @after_username_changed = []
      @after_password_changed = []
      @after_group_added = []
      @after_group_removed = []

      case arg
      when String
        self['name'] = arg
        self['sites'] = []
        self['groups'] = {}
      when Hash
        load(arg)
      when nil
        @uninitialized = true
      end
    end

    def load(hash)
      @loading = true

      if !hash.has_key?('name')
        raise ArgumentError, "hash is missing the 'name' key"
      end
      if !hash['name'].is_a?(String)
        raise ArgumentError, "name is not a String"
      end
      self['name'] = hash['name']

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

      self['sites'] = []
      hash['sites'].each_with_index do |site_hash, site_index|
        if !site_hash.is_a?(Hash)
          raise ArgumentError, "site #{site_index} is not a Hash"
        end

        begin
          site = Site.new(site_hash)
          add_site(site)
        rescue SiteError => e
          raise ArgumentError, "site #{site_index} is not valid: #{e.message}"
        end
      end

      self['groups'] = {}
      hash['groups'].each_pair do |group_name, group_hash|
        if !group_name.is_a?(String)
          raise ArgumentError, "group key is not a String"
        end
        if !group_hash.is_a?(Hash)
          raise ArgumentError, "group value for #{group_name.inspect} is not a Hash"
        end

        begin
          group = Group.new(group_hash)
          add_group(group)
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

    def name
      self['name']
    end

    def sites
      self['sites']
    end

    def groups
      self['groups']
    end

    def add_site(site)
      raise "add_site is not allowed until Group is initialized" if @uninitialized && !@loading
      add_site_without_callbacks(site)

      @after_site_added.each do |block|
        block.call(self, site)
      end
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

      @after_site_removed.each do |block|
        block.call(self, site)
      end
    end

    def add_group(group)
      raise "add_group is not allowed until Group is initialized" if @uninitialized && !@loading
      add_group_without_callbacks(group)

      @after_group_added.each do |block|
        block.call(self, group)
      end
    end

    def group(group_name)
      groups[group_name]
    end

    def group_names
      groups.keys
    end

    def remove_group(group_name)
      raise "remove_group is not allowed until Group is initialized" if @uninitialized && !@loading
      if !groups.has_key?(group_name)
        raise GroupError, "group doesn't exist"
      end
      group = groups.delete(group_name)

      @after_group_removed.each do |block|
        block.call(self, group)
      end
    end

    def after_site_added(&block)
      @after_site_added << block
    end

    def after_site_removed(&block)
      @after_site_removed << block
    end

    def after_username_changed(&block)
      @after_username_changed << block
    end

    def after_password_changed(&block)
      @after_password_changed << block
    end

    def after_group_added(&block)
      @after_group_added << block
    end

    def after_group_removed(&block)
      @after_group_removed << block
    end

    def encode_with(coder)
      coder.represent_map(nil, self)
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
      sites << site
      add_site_hooks_for(site)
    end

    def add_group_without_callbacks(group)
      if !group.is_a?(Group)
        raise GroupError, "group is not a Group"
      end
      if groups.has_key?(group.name)
        raise GroupError, "group already exists"
      end
      groups[group.name] = group
    end

    def add_site_hooks_for(site)
      site.after_username_changed do |site|
        @after_username_changed.each do |block|
          block.call(self, site)
        end
      end
      site.after_password_changed do |site|
        @after_password_changed.each do |block|
          block.call(self, site)
        end
      end
    end
  end
end
