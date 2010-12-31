module Keyrack
  module UI
    class Console
      attr_accessor :database
      def initialize
        @highline = HighLine.new
      end

      def get_password
        @highline.ask("Keyrack password: ") { |q| q.echo = false }
      end

      def menu
        entries = []
        choices = %w{n q}
        @database.sites.each_with_index do |site, i|
          entry = @database.get(site)
          entries << entry
          choices << "#{i+1}"
          @highline.say("% 2d. %s [%s]" % [i+1, site, entry[:username]])
        end
        @highline.say(" n. Add new")
        if @database.dirty?
          @highline.say(" s. Save")
          choices << "s"
        end
        @highline.say(" q. Quit")
        result = @highline.ask(" ?  ") { |q| q.in = choices }
        case result
        when "n"
          :new
        when "s"
          :save
        when "q"
          if @database.dirty? && !@highline.agree("Really quit?  You have unsaved changes! [yn] ")
            nil
          else
            :quit
          end
        else
          Clipboard.copy(entries[result.to_i - 1][:password])
          @highline.say("The password has been copied to your clipboard.")
          nil
        end
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
            @highline.say("Passwords didn't match.  Try again!")
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
    end
  end
end
