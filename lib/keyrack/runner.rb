module Keyrack
  class Runner
    def initialize(argv)
      @config_path = "~/.keyrack"
      OptionParser.new do |opts|
        opts.on("-d", "--directory [PATH]", "Specify configuration path (Default: #{@config_path}") do |f|
          @config_path = f
        end
      end.parse(argv)
      @config_path = File.expand_path(@config_path)
      @ui = UI::Console.new

      if Dir.exist?(@config_path)
        @options = YAML.load_file(File.join(@config_path, "config"))
        password = @ui.get_password
        rsa_key = Utils.open_rsa_key(File.expand_path(@options['rsa'], @config_path), password)
        aes_data = Utils.open_aes_data(File.expand_path(@options['aes'], @config_path), rsa_key)
      else
        Dir.mkdir(@config_path)
        @options = {}
        @ui.display_first_time_notice

        # RSA
        rsa_options = @ui.rsa_setup
        rsa_key, rsa_pem = Utils.generate_rsa_key(rsa_options['password'])
        rsa_path = File.expand_path(rsa_options['path'], @config_path)
        File.open(rsa_path, 'w') { |f| f.write(rsa_pem) }
        @options['rsa'] = rsa_path

        # AES
        aes_data = {
          'key' => Utils.generate_aes_key,
          'iv'  => Utils.generate_aes_key
        }
        dump = Marshal.dump(aes_data)
        aes_path = File.expand_path('aes', @config_path)
        File.open(aes_path, 'w') { |f| f.write(rsa_key.public_encrypt(dump)) }
        @options['aes'] = aes_path

        # Store
        store_options = @ui.store_setup
        if store_options['type'] == 'filesystem'
          store_options['path'] = File.expand_path(store_options['path'], @config_path)
        end
        @options['store'] = store_options

        # Write out config
        File.open(File.expand_path('config', @config_path), 'w') { |f| f.print(@options.to_yaml) }
      end
      store = Store[@options['store']['type']].new(@options['store'].reject { |k, _| k == 'type' })
      @database = Database.new(aes_data['key'], aes_data['iv'], store)
      @ui.database = @database
      main_loop
    end

    def main_loop
      options = {}
      loop do
        choice = @ui.menu(options)

        case choice
        when :new
          result = @ui.get_new_entry
          @database.add(result[:site], result[:username], result[:password], options)
        when :delete
          @ui.delete_entry(options)
        when :new_group
          options = @ui.get_new_group
        when :save
          @database.save
        when :quit
          break
        when Hash
          options = choice
        when :top
          options = {}
        end
      end
    end
  end
end
