module Keyrack
  module UI
    class Console
      attr_accessor :mode

      def initialize
        @highline = HighLine.new
        @mode = :copy
      end

      def get_password
        @highline.ask("Keyrack password: ") { |q| q.echo = false }.to_s
      end

      def menu(options)
        current_group = options[:group]
        dirty = options[:dirty]
        at_top = options[:at_top]

        site_names = current_group.site_names
        subgroup_names = current_group.group_names

        # Collect the selections
        selections = []
        max_width = 0
        choices = {'n' => :new, 'q' => :quit, 'm' => :mode}
        selection_index = 1
        subgroup_names.each do |group_name|
          choices[selection_index.to_s] = {:group => group_name}

          text = @highline.color(group_name, :green)
          width = group_name.length
          selections.push({:width => width, :text => text})

          max_width = width if width > max_width
          selection_index += 1
        end

        site_names.each do |site_name|
          site = current_group.site(site_name)
          site.usernames.each do |username|
            choices[selection_index.to_s] = {:site => site_name, :username => username}

            text = "%s [%s]" % [site_name, username]
            width = text.length
            selections.push({:width => width, :text => text})

            max_width = width if width > max_width
            selection_index += 1
          end
        end

        title = {}
        if at_top
          title[:text] = @highline.color("Keyrack Main Menu", :yellow)
          title[:width] = 17
        else
          title[:text] = @highline.color(current_group.name, :green)
          title[:width] = current_group.name.length
        end

        columnize_menu(selections, max_width, title)

        @highline.say("Mode: #{@mode}")
        commands = "Commands: [n]ew"
        if !site_names.empty?
          choices['e'] = :edit
          commands << " [e]dit"
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

        answer = @highline.ask("? ") { |q| q.in = choices.keys }.to_s
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
        @highline.ask("Group: ") { |q| q.validate = /^\w[\w\s]*$/ }.to_s
      end

      def get_new_entry
        result = {}
        result[:site]     = @highline.ask("Label: ").to_s
        result[:username] = @highline.ask("Username: ").to_s
        result[:password] = get_new_password
        result[:password].nil? ? nil : result
      end

      def display_first_time_notice
        @highline.say("This looks like your first time using Keyrack.  I'll need to ask you a few questions first.")
      end

      def password_setup
        password = confirmation = nil
        loop do
          password = @highline.ask("New passphrase: ") { |q| q.echo = false }.to_s
          confirmation = @highline.ask("Confirm passphrase: ") { |q| q.echo = false }.to_s
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
          result['host'] = @highline.ask("Host: ").to_s
          result['user'] = @highline.ask("User: ").to_s
          result['path'] = @highline.ask("Remote path: ").to_s
        end

        result
      end

      def choose_entry_to_edit(group)
        choices = {'c' => :cancel}
        index = 1

        title = {
          :text => @highline.color("Choose entry", :cyan),
          :width => 12
        }

        selections = []
        max_width = 0
        group.site_names.each do |site_name|
          site = group.site(site_name)
          site.usernames.each do |username|
            choices[index.to_s] = {:site => site_name, :username => username}

            text = "%s [%s]" % [site_name, username]
            width = text.length
            selections.push({:text => text, :width => width})
            max_width = width if width > max_width

            index += 1
          end
        end

        columnize_menu(selections, max_width, title)

        @highline.say("c. Cancel")

        answer = @highline.ask("? ") { |q| q.in = choices.keys }.to_s
        result = choices[answer]
        if result == :cancel
          nil
        else
          result
        end
      end

      def edit_entry(site_name, username)
        colored_entry = @highline.color("#{site_name} [#{username}]", :cyan)
        @highline.say("Editing entry: #{colored_entry}")
        @highline.say("u. Change username")
        @highline.say("p. Change password")
        @highline.say("d. Delete")
        @highline.say("c. Cancel")

        case @highline.ask("? ") { |q| q.in = %w{u p d c} }.to_s
        when "u"
          :change_username
        when "p"
          :change_password
        when "d"
          :delete
        when "c"
          nil
        end
      end

      def change_username(old_username)
        colored_old_username = @highline.color(old_username, :cyan)
        @highline.say("Current username: #{colored_old_username}")
        @highline.ask("New username (blank to cancel): ") { |q| q.validate = /\S/ }.to_s
      end

      def confirm_overwrite_entry(site_name, username)
        entry_name = @highline.color("#{site_name} [#{username}]", :cyan)
        @highline.agree("There's already an entry for: #{entry_name}. Do you want to overwrite it? [yn] ")
      end

      def confirm_delete_entry(site_name, username)
        entry = @highline.color("#{site_name} [#{username}]", :red)
        @highline.agree("You're about to delete #{entry}. Are you sure? [yn] ")
      end

      def display_invalid_password_notice
        @highline.say("Invalid password.")
      end

      def get_new_password
        result = nil
        case @highline.ask("Generate password? [ync] ") { |q| q.in = %w{y n c} }.to_s
        when "y"
          result = get_generated_password
          if result.nil?
            result = get_manual_password
          end
        when "n"
          result = get_manual_password
        end
        result
      end

      def get_generated_password
        password = nil
        loop do
          password = Utils.generate_password
          colored_password = @highline.color(password, :cyan)
          case @highline.ask("Generated #{colored_password}.  Sound good? [ync] ") { |q| q.in = %w{y n c} }.to_s
          when "y"
            break
          when "c"
            password = nil
            break
          end
        end
        password
      end

      def get_manual_password
        password = nil
        loop do
          password = @highline.ask("Password: ") { |q| q.echo = false }.to_s
          confirmation = @highline.ask("Password (again): ") { |q| q.echo = false }.to_s
          if password == confirmation
            break
          end
          @highline.say("Passwords didn't match. Try again!")
        end
        password
      end

      def columnize_menu(selections, max_width, title = nil)
        terminal_size = HighLine::SystemExtensions.terminal_size

        if selections.empty?
          if title
            @highline.say("=== #{title[:text]} ===")
          end
          return
        end

        # add in width for numbers
        number_width = Math.log10(selections.count).floor + 1
        max_width += number_width + 2

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
        total_width = num_columns * max_width + (num_columns - 1)

        if title
          padding_total = total_width - title[:width] - 2
          padding_left = [padding_total / 2, 3].max
          padding_right = [padding_total - padding_left, 3].max
          @highline.say(("=" * padding_left) + " #{title[:text]} " + ("=" * padding_right))
        end

        selection_index = 0
        catch(:stop) do
          loop do
            num_columns.downto(1) do |i|
              selection = selections[selection_index]
              throw(:stop) if selection.nil?

              label = "%#{number_width}d. " % (selection_index + 1)
              if i == 1 || selection_index == (selections.count - 1)
                @highline.say(label + selection[:text])
              else
                spaces = max_width - (selection[:width] + number_width + 2) + 1
                @highline.say(label + selection[:text] + (" " * spaces))
              end
              selection_index += 1
            end
          end
        end
      end
    end
  end
end
