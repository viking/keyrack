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
        choices = %w{n s q}
        @database.sites.each_with_index do |site, i|
          entry = @database.get(site)
          entries << entry
          choices << "#{i+1}"
          @highline.say("% 2d. %s [%s]" % [i+1, site, entry[:username]])
        end
        @highline.say(" n. Add new")
        @highline.say(" s. Save")
        @highline.say(" q. Quit")
        result = @highline.ask(" ?  ") { |q| q.in = choices }
        case result
        when "n"
          :new
        when "s"
          :save
        when "q"
          :quit
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
            if @highline.agree("Generated '#{password}'.  Sound good? [yn] ")
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
    end
  end
end
