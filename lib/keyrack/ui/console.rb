module Keyrack
  module UI
    class Console
      attr_accessor :database, :mode

      def initialize
        @highline = HighLine.new
        @mode = :copy
      end

      def get_password
        @highline.ask("Keyrack password: ") { |q| q.echo = false }
      end

      def menu(options = {})
        choices = {'n' => :new, 'q' => :quit, 'm' => :mode}
        index = 1

        sites = @database.sites(options)
        count = sites.length
        count += @database.groups.length  if !options[:group]
        width = count / 10

        if !options[:group]
          # Can't have subgroups (yet?).
          @highline.say("=== #{@highline.color("Keyrack Main Menu", :yellow)} ===")
          @database.groups.each do |group|
            choices[index.to_s] = {:group => group}
            @highline.say(" %#{width}d. %s" % [index, @highline.color(group, :green)])
            index += 1
          end
        else
          @highline.say("===== #{@highline.color(options[:group], :green)} =====")
        end

        sites.each do |site|
          entry = @database.get(site, options)
          choices[index.to_s] = entry
          @highline.say(" %#{width}d. %s [%s]" % [index, site, entry[:username]])
          index += 1
        end

        @highline.say("Mode: #{mode}")
        commands = "Commands: [n]ew"
        if !sites.empty?
          choices['d'] = :delete
          commands << " [d]elete"
        end
        if !options[:group]
          choices['g'] = :new_group
          commands << " [g]roup"
        else
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
            result
          else
            if mode == :copy
              Copier(result[:password])
              @highline.say("The password has been copied to your clipboard.")
            elsif mode == :print
              password = @highline.color(result[:password], :cyan)
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

      def get_new_group
        group = @highline.ask("Group: ") { |q| q.validate = /^\w[\w\s]*$/ }
        {:group => group}
      end

      def get_new_entry
        result = {}
        result[:site]     = @highline.ask("Label: ")
        result[:username] = @highline.ask("Username: ")
        if @highline.agree("Generate password? [yn] ")
          loop do
            password = Utils.generate_password
            if @highline.agree("Generated #{@highline.color(password, :blue)}.  Sound good? [yn] ")
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

      def rsa_setup
        password = confirmation = nil
        loop do
          password = @highline.ask("New passphrase: ") { |q| q.echo = false }
          confirmation = @highline.ask("Confirm passphrase: ") { |q| q.echo = false }
          break if password == confirmation
          @highline.say("Passphrases didn't match.")
        end
        { 'password' => password, 'path' => 'rsa' }
      end

      def store_setup
        result = {}
        result['type'] = @highline.choose do |menu|
          menu.header = "Choose storage type:"
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
        index = 1
        @highline.say("Choose entry to delete:")
        @database.sites(options).each do |site|
          entry = @database.get(site, options)
          choices[index.to_s] = {:site => site, :username => entry[:username]}
          @highline.say("% 2d. %s [%s]" % [index, site, entry[:username]])
          index += 1
        end
        @highline.say(" c. Cancel")

        answer = @highline.ask(" ?  ") { |q| q.in = choices.keys }
        result = choices[answer]
        if result != :cancel
          entry = @highline.color("#{result[:site]} [#{result[:username]}]", :red)
          if @highline.agree("You're about to delete #{entry}.  Are you sure? [yn] ")
            @database.delete(result[:site], options)
          end
        end
      end
    end
  end
end
