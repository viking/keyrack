module Keyrack
  module UI
    class Console
      attr_accessor :mode

      def initialize
        @highline = HighLine.new
        @mode = :copy
      end

      def database=(database)
        @database = database
      end

      def get_password
        @highline.ask("Keyrack password: ") { |q| q.echo = false }
      end

      def menu(options = {})
        choices = {'n' => :new, 'q' => :quit, 'm' => :mode}
        index = 1

        if !options.has_key?(:group)
          options = options.merge(:group => [])
        end
        current_group = get_group(options[:group])

        site_names = current_group.site_names
        subgroup_names = current_group.group_names
        count = site_names.inject(0) do |sum, name|
          sum + current_group.site(name).usernames.length
        end
        count += subgroup_names.length
        number_width = count / 10

        if at_top?(current_group)
          @highline.say("=== #{@highline.color("Keyrack Main Menu", :yellow)} ===")
        else
          @highline.say("===== #{@highline.color(current_group.name, :green)} =====")
        end

        subgroup_names.each do |group_name|
          choices[index.to_s] = {:group => group_name}
          @highline.say(" %#{number_width}d. %s" % [index, @highline.color(group_name, :green)])
          index += 1
        end

        site_names.each do |site_name|
          site = current_group.site(site_name)
          site.usernames.each do |username|
            choices[index.to_s] = {:site => site_name, :username => username}
            @highline.say(" %#{number_width}d. %s [%s]" % [index, site_name, username])
            index += 1
          end
        end

        @highline.say("Mode: #{@mode}")
        commands = "Commands: [n]ew"
        if !site_names.empty?
          choices['d'] = :delete
          commands << " [d]elete"
        end

        choices['g'] = :new_group
        commands << " [g]roup"

        if !at_top?(current_group)
          choices['t'] = :top
          commands << " [t]op"
        end

        if @database.dirty?
          choices['s'] = :save
          commands << " [s]ave"
        end
        commands << " [m]ode [q]uit"
        @highline.say(commands)

        answer = @highline.ask(" ? ") { |q| q.in = choices.keys }
        result = choices[answer]
        case result
        when Symbol
          if result == :quit && @database.dirty? && !@highline.agree("Really quit?  You have unsaved changes! [yn] ")
            nil
          elsif result == :mode
            @mode = @mode == :copy ? :print : :copy
            nil
          else
            result
          end
        when Hash
          if result.has_key?(:group)
            options.merge(:group => options[:group] + [result[:group]])
          else
            password = current_group.site(result[:site]).
              password_for(result[:username])

            if @mode == :copy
              Clipboard.copy(password)
              @highline.say("The password has been copied to your clipboard.")
            elsif @mode == :print
              password = @highline.color(password, :cyan)
              @highline.ask("Here you go: #{password}. Done? ") do |question|
                question.echo = false
                if HighLine::SystemExtensions::CHARACTER_MODE != 'stty'
                  question.character = true
                  question.overwrite = true
                end
              end
            end
            nil
          end
        end
      end

      def at_top?(group)
        group == @database.top_group
      end

      def get_new_group(options = {})
        group = @highline.ask("Group: ") { |q| q.validate = /^\w[\w\s]*$/ }
        {:group => (options[:group] || []) + [group]}
      end

      def get_new_entry
        result = {}
        result[:site]     = @highline.ask("Label: ")
        result[:username] = @highline.ask("Username: ")
        if @highline.agree("Generate password? [yn] ")
          loop do
            password = Utils.generate_password
            if @highline.agree("Generated #{@highline.color(password, :cyan)}.  Sound good? [yn] ")
              result[:password] = password
              break
            end
          end
        else
          loop do
            password = @highline.ask("Password: ") { |q| q.echo = false }
            confirmation = @highline.ask("Password (again): ") { |q| q.echo = false }
            if password == confirmation
              result[:password] = password
              break
            end
            @highline.say("Passwords didn't match. Try again!")
          end
        end
        result
      end

      def display_first_time_notice
        @highline.say("This looks like your first time using Keyrack.  I'll need to ask you a few questions first.")
      end

      def password_setup
        password = confirmation = nil
        loop do
          password = @highline.ask("New passphrase: ") { |q| q.echo = false }
          confirmation = @highline.ask("Confirm passphrase: ") { |q| q.echo = false }
          break if password == confirmation
          @highline.say("Passphrases didn't match.")
        end
        { 'password' => password }
      end

      def store_setup
        result = {}
        result['type'] = @highline.choose do |menu|
          menu.header = "Choose storage type"
          menu.choices("filesystem", "ssh")
        end

        case result['type']
        when 'filesystem'
          result['path'] = 'database'
        when 'ssh'
          result['host'] = @highline.ask("Host: ")
          result['user'] = @highline.ask("User: ")
          result['path'] = @highline.ask("Remote path: ")
        end

        result
      end

      def delete_entry(options = {})
        choices = {'c' => :cancel}
        current_group = get_group(options[:group] || [])
        index = 1

        @highline.say("Choose entry to delete:")
        current_group.site_names.each do |site_name|
          site = current_group.site(site_name)
          site.usernames.each do |username|
            choices[index.to_s] = {:site => site_name, :username => username}
            @highline.say("% 2d. %s [%s]" % [index, site_name, username])
            index += 1
          end
        end
        @highline.say(" c. Cancel")

        answer = @highline.ask(" ?  ") { |q| q.in = choices.keys }
        result = choices[answer]
        if result != :cancel
          entry = @highline.color("#{result[:site]} [#{result[:username]}]", :red)
          if @highline.agree("You're about to delete #{entry}.  Are you sure? [yn] ")
            return result
          end
        end
        nil
      end

      private

      def get_group(group_tree)
        group_tree.inject(@database.top_group) do |memo, obj|
          memo.group(obj)
        end
      end
    end
  end
end
