module Keyrack
  class Group < Hash
    def initialize(arg)
      @after_site_added = []
      @after_site_removed = []
      @after_login_added = []
      @after_username_changed = []
      @after_password_changed = []
      @after_login_removed = []
      @after_group_added = []
      @after_group_removed = []

      case arg
      when String
        self['name'] = arg
        self['sites'] = {}
        self['groups'] = {}
      when Hash
        if !arg.has_key?('name')
          raise ArgumentError, "hash is missing the 'name' key"
        end
        if !arg['name'].is_a?(String)
          raise ArgumentError, "name is not a String"
        end
        self['name'] = arg['name']

        if !arg.has_key?('sites')
          raise ArgumentError, "hash is missing the 'sites' key"
        end
        if !arg['sites'].is_a?(Hash)
          raise ArgumentError, "sites is not a Hash"
        end

        if !arg.has_key?('groups')
          raise ArgumentError, "hash is missing the 'groups' key"
        end
        if !arg['groups'].is_a?(Hash)
          raise ArgumentError, "groups is not a Hash"
        end

        self['sites'] = {}
        arg['sites'].each_pair do |site_name, site_hash|
          if !site_name.is_a?(String)
            raise ArgumentError, "site key is not a String"
          end
          if !site_hash.is_a?(Hash)
            raise ArgumentError, "site value for #{site_name.inspect} is not a Hash"
          end

          begin
            site = Site.new(site_hash)
            add_site_without_callbacks(site)
          rescue SiteError => e
            raise ArgumentError, "site #{site_name.inspect} is not valid: #{e.message}"
          end

          if site.name != site_name
            raise ArgumentError, "site name mismatch: #{site_name.inspect} != #{site.name.inspect}"
          end
        end

        self['groups'] = {}
        arg['groups'].each_pair do |group_name, group_hash|
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
      end
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
      add_site_without_callbacks(site)

      @after_site_added.each do |block|
        block.call(self, site)
      end
    end

    def site(site_name)
      sites[site_name]
    end

    def site_names
      sites.keys
    end

    def remove_site(site_name)
      if !sites.has_key?(site_name)
        raise GroupError, "site doesn't exist"
      end
      site = sites.delete(site_name)

      @after_site_removed.each do |block|
        block.call(self, site)
      end
    end

    def add_group(group)
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

    def after_login_added(&block)
      @after_login_added << block
    end

    def after_login_removed(&block)
      @after_login_removed << block
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
      if sites.has_key?(site.name)
        raise GroupError, "site already exists"
      end
      sites[site.name] = site
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
      site.after_login_added do |site, username, password|
        @after_login_added.each do |block|
          block.call(self, site, username, password)
        end
      end
      site.after_username_changed do |site, old_username, new_username|
        @after_username_changed.each do |block|
          block.call(self, site, old_username, new_username)
        end
      end
      site.after_password_changed do |site, username, old_password, new_password|
        @after_password_changed.each do |block|
          block.call(self, site, username, old_password, new_password)
        end
      end
      site.after_login_removed do |site, username, password|
        @after_login_removed.each do |block|
          block.call(self, site, username, password)
        end
      end
    end
  end
end
