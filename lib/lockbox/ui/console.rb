module Lockbox
  module UI
    class Console
      attr_accessor :database
      def initialize
        @highline = HighLine.new
      end

      def get_password
        @highline.ask("Lockbox password: ") { |q| q.echo = false }
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
        result[:site]     = @highline.ask("Site:     ")
        result[:username] = @highline.ask("Username: ")
        result[:password] = @highline.ask("Password: ")
        result
      end
    end
  end
end
