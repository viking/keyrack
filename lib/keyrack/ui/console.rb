module Keyrack
  module UI
    class Console
      attr_accessor :mode

      def initialize
        @highline = HighLine.new
        @mode = :copy
      end

      def get_password
        @highline.ask("Keyrack password: ") { |q| q.echo = false }
      end

      def menu(options)
        terminal_size = HighLine::SystemExtensions.terminal_size

        current_group = options[:group]
        dirty = options[:dirty]
        at_top = options[:at_top]

        site_names = current_group.site_names
        subgroup_names = current_group.group_names
        selection_count = site_names.inject(0) do |sum, name|
          sum + current_group.site(name).usernames.length
        end
        selection_count += subgroup_names.length
        number_width = selection_count / 10

        # Collect the selections
        selections = []
        max_width = 0
        choices = {'n' => :new, 'q' => :quit, 'm' => :mode}
        selection_index = 1
        subgroup_names.each do |group_name|
          choices[selection_index.to_s] = {:group => group_name}
          template = " %#{number_width}d. %%s" % selection_index
          colorized = template % @highline.color(group_name, :green)
          uncolorized = template % group_name
          width = uncolorized.length
          selections.push({ :width => width, :text => colorized })
          max_width = width if width > max_width
          selection_index += 1
        end
        site_names.each do |site_name|
          site = current_group.site(site_name)
          site.usernames.each do |username|
            choices[selection_index.to_s] = {:site => site_name, :username => username}
            text = " %#{number_width}d. %s [%s]" % [selection_index, site_name, username]
            width = text.length
            selections.push({ :width => width, :text => text })
            max_width = width if width > max_width
            selection_index += 1
          end
        end
        multiples = max_width == 0 ? 1 : terminal_size[0] / max_width
        num_columns =
          if multiples > 1
            if (terminal_size[0] - (multiples * max_width)) < (multiples - 1)
              # If there aren't sufficient spaces, decrease column count
              multiples - 1
            else
              multiples
            end
          else
            1
          end
        #puts "Terminal width: %d; Max width: %d; Multiples: %d; Columns: %d" %
          #[ terminal_size[0], max_width, multiples, num_columns ]
        menu_width = num_columns * max_width + (num_columns - 1)

        if at_top
          title = @highline.color("Keyrack Main Menu", :yellow)
          title_width = 17
        else
          title = @highline.color(current_group.name, :green)
          title_width = current_group.name.length
        end
        padding_total = menu_width - title_width - 2
        padding_left = [padding_total / 2, 3].max
        padding_right = [padding_total - padding_left, 3].max
        @highline.say(("=" * padding_left) + " #{title} " + ("=" * padding_right))

        selection_index = 0
        catch(:stop) do
          loop do
            num_columns.downto(1) do |i|
              selection = selections[selection_index]
              throw(:stop) if selection.nil?

              if i == 1 || selection_index == (selection_count - 1)
                @highline.say(selection[:text])
              else
                spaces = max_width - selection[:width] + 1
                @highline.say(selection[:text] + (" " * spaces))
              end
              selection_index += 1
            end
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

        if options[:enable_up]
          choices['u'] = :up
          commands << " [u]p"
        end

        if !at_top
          choices['t'] = :top
          commands << " [t]op"
        end

        if dirty
          choices['s'] = :save
          commands << " [s]ave"
        end
        commands << " [m]ode [q]uit"
        @highline.say(commands)

        answer = @highline.ask(" ? ") { |q| q.in = choices.keys }
        result = choices[answer]
        case result
        when Symbol
          if result == :quit && dirty && !@highline.agree("Really quit?  You have unsaved changes! [yn] ")
            nil
          elsif result == :mode
            @mode = @mode == :copy ? :print : :copy
            nil
          else
            result
          end
        when Hash
          if result.has_key?(:group)
            {:group => current_group.group(result[:group])}
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

      def get_new_group(options = {})
        @highline.ask("Group: ") { |q| q.validate = /^\w[\w\s]*$/ }
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
        password
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

      def delete_entry(group)
        choices = {'c' => :cancel}
        index = 1

        @highline.say("Choose entry to delete:")
        group.site_names.each do |site_name|
          site = group.site(site_name)
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

      def confirm_overwrite_entry(site_name, username)
        entry_name = @highline.color("#{site_name} [#{username}]", :cyan)
        @highline.agree("There's already an entry for: #{entry_name}. Do you want to overwrite it? [yn] ")
      end

      def display_invalid_password_notice
        @highline.say("Invalid password.")
      end
    end
  end
end
