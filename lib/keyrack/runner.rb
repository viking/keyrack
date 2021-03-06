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
      begin
        @database = Database.new(password, store)
        main_loop
      rescue Scrypty::IncorrectPasswordError
        @ui.display_invalid_password_notice
      end
    end

    def main_loop
      group_tree = [@database.top_group]
      open = false
      loop do
        current_group = group_tree.last
        menu_options = {
          :group => current_group,
          :at_top => at_top?(current_group),
          :dirty => @database.dirty?,
          :enable_up => group_tree.length > 2,
          :open => open
        }
        choice = @ui.menu(menu_options)

        case choice
        when :open
          open = true
        when :collapse
          open = false
        when :new
          result = @ui.get_new_entry
          next if result.nil?

          new_site = Site.new(*result.values_at(:site, :username, :password))
          if site = current_group.sites.find { |s| s == new_site }
            if @ui.confirm_overwrite_entry(site)
              site.password = new_site.password
            end
          else
            current_group.add_site(new_site)
          end
        when :edit
          result = @ui.choose_entry_to_edit(current_group)
          next if result.nil?
          site = result[:site]

          loop do
            which = @ui.edit_entry(site)
            case which
            when :change_username
              new_username = @ui.change_username(site.username)
              if new_username
                site.username = new_username
              end
            when :change_password
              new_password = @ui.get_new_password
              if new_password
                site.password = new_password
              end
            when :delete
              if @ui.confirm_delete_entry(site)
                current_group.remove_site(site)
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
