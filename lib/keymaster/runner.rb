module Keymaster
  class Runner
    def initialize(argv)
      OptionParser.new do |opts|
        opts.on("-c", "--config FILE", "Specify configuration file") do |f|
          @options = YAML.load_file(f)
        end
      end.parse(argv)

      @ui = UI::Console.new
      password = @ui.get_password
      @database = Database.new(@options.merge(:password => password))
      @ui.database = @database

      main_loop
    end

    def main_loop
      loop do
        case @ui.menu
        when :new
          result = @ui.get_new_entry
          @database.add(result[:site], result[:username], result[:password])
        when :save
          @database.save
        when :quit
          break
        end
      end
    end
  end
end
