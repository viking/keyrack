module Keyrack
  class Group < Hash
    def initialize(arg)
      case arg
      when String
        self[:name] = arg
        self[:sites] = {}
        self[:groups] = {}
      when Hash
        if !arg.has_key?(:name)
          raise ArgumentError, "hash is missing the :name key"
        end
        if !arg[:name].is_a?(String)
          raise ArgumentError, "name is not a String"
        end
        self[:name] = arg[:name]

        if !arg.has_key?(:sites)
          raise ArgumentError, "hash is missing the :sites key"
        end
        if !arg[:sites].is_a?(Hash)
          raise ArgumentError, "sites is not a Hash"
        end

        if !arg.has_key?(:groups)
          raise ArgumentError, "hash is missing the :groups key"
        end
        if !arg[:groups].is_a?(Hash)
          raise ArgumentError, "groups is not a Hash"
        end

        self[:sites] = {}
        arg[:sites].each_pair do |site_name, site_hash|
          if !site_name.is_a?(String)
            raise ArgumentError, "site key is not a String"
          end
          if !site_hash.is_a?(Hash)
            raise ArgumentError, "site value for #{site_name.inspect} is not a Hash"
          end

          begin
            site = self[:sites][site_name] = Site.new(site_hash)
          rescue SiteError => e
            raise ArgumentError, "site #{site_name.inspect} is not valid: #{e.message}"
          end

          if site.name != site_name
            raise ArgumentError, "site name mismatch: #{site_name.inspect} != #{site.name.inspect}"
          end
        end

        self[:groups] = {}
        arg[:groups].each_pair do |group_name, group_hash|
          if !group_name.is_a?(String)
            raise ArgumentError, "group key is not a String"
          end
          if !group_hash.is_a?(Hash)
            raise ArgumentError, "group value for #{group_name.inspect} is not a Hash"
          end

          begin
            group = self[:groups][group_name] = Group.new(group_hash)
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
      self[:name]
    end

    def sites
      self[:sites]
    end

    def groups
      self[:groups]
    end

    def add_site(site)
      if !site.is_a?(Site)
        raise GroupError, "site is not a Site"
      end
      if sites.has_key?(site.name)
        raise GroupError, "site already exists"
      end
      sites[site.name] = site
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
      sites.delete(site_name)
    end

    def add_group(group)
      if !group.is_a?(Group)
        raise GroupError, "group is not a Group"
      end
      if groups.has_key?(group.name)
        raise GroupError, "group already exists"
      end
      groups[group.name] = group
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
      groups.delete(group_name)
    end
  end
end
