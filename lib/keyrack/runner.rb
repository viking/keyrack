module Keyrack
  class Runner
    def initialize(argv)
      opts = { :path => "~/.keyrack" }
      OptionParser.new do |optparse|
        optparse.on("-d", "--directory [PATH]", "Specify configuration path (Default: #{@config_path}") do |path|
          opts[:path] = path
        end
      end.parse(argv)
      @config_path = File.expand_path(opts[:path])
      @ui = UI::Console.new

      database_exists = false
      if Dir.exist?(@config_path)
        config_filename = File.join(@config_path, "config.yml")
        if File.exist?(config_filename)
          database_exists = true
          @options = YAML.load_file(config_filename)
          password = @ui.get_password
        end
      end

      if !database_exists
        FileUtils.mkdir_p(@config_path)
        @options = {}
        @ui.display_first_time_notice

        # Password
        password = @ui.password_setup

        # Store
        @options['store'] = @ui.store_setup

        # Write out config
        File.open(File.expand_path('config.yml', @config_path), 'w') { |f| f.print(@options.to_yaml) }
      end

      # Expand relative paths, using config_path as parent
      if @options['store']['type'] == 'filesystem' &&
            @options['store'].has_key?('path')

        @options['store']['path'] =
          File.expand_path(@options['store']['path'], @config_path)
      end

      store = Store[@options['store']['type']].new(@options['store'].reject { |k, _| k == 'type' })
      @database = Database.new(password, store)
      main_loop
    end

    def main_loop
      group_tree = [@database.top_group]
      loop do
        current_group = group_tree.last
        menu_options = {
          :group => current_group,
          :at_top => at_top?(current_group),
          :dirty => @database.dirty?,
          :enable_up => group_tree.length > 2
        }
        choice = @ui.menu(menu_options)

        case choice
        when :new
          result = @ui.get_new_entry
          next if result.nil?

          new_site = false
          existing_sites = current_group.site_names
          site =
            if existing_sites.include?(result[:site])
              current_group.site(result[:site])
            else
              new_site = true
              Site.new(result[:site])
            end

          if !new_site && site.usernames.include?(result[:username])
            if @ui.confirm_overwrite_entry(result[:site], result[:username])
              site.change_password(result[:username], result[:password])
            end
          else
            site.add_login(result[:username], result[:password])
          end
          current_group.add_site(site)  if new_site
        when :edit
          result = @ui.choose_entry_to_edit(current_group)
          site_name, username = result.values_at(:site, :username)
          site = current_group.site(site_name)

          loop do
            which = @ui.edit_entry(site_name, username)
            case which
            when :change_username
              new_username = @ui.change_username(username)
              if new_username
                site.change_username(username, new_username)
                username = new_username
              end
            when :change_password
              new_password = @ui.get_new_password
              if new_password
                site.change_password(username, new_password)
              end
            when :delete
              if @ui.confirm_delete_entry(site_name, username)
                site.remove_login(username)
                break
              end
            when nil
              break
            end
          end
        when :new_group
          group_name = @ui.get_new_group
          group = Group.new(group_name)
          current_group.add_group(group)
          group_tree << group
        when :save
          password = @ui.get_password
          if !@database.save(password)
            @ui.display_invalid_password_notice
          end
        when :quit
          break
        when Hash
          if choice[:group]
            group_tree << choice[:group]
          end
        when :top
          while group_tree.length > 1
            group_tree.pop
          end
        when :up
          group_tree.pop
        end
      end
    end

    private

    def at_top?(group)
      group.equal?(@database.top_group)
    end
  end
end
