module Keymaster
  module UI
    class Console
      attr_accessor :database
      def initialize
        @highline = HighLine.new
      end

      def get_password
        @highline.ask("Keymaster password: ") { |q| q.echo = false }
      end

      def menu
        choices = @database.sites.inject({}) do |hsh, site|
          entry = @database.get(site)
          hsh["#{site} [#{entry[:username]}]"] = entry
          hsh
        end
        result = @highline.choose(*choices.keys.sort, "Add new", "Save", "Quit")
        case result
        when "Add new"
          :new
        when "Save"
          :save
        when "Quit"
          :quit
        else
          Clipboard.copy(choices[result][:password])
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
