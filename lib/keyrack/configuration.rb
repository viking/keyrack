module Keyrack
  class Configuration
    def self.load(filename)
      Configuration.new(YAML.load_file(filename))
    end

    attr_reader :options

    def initialize(options = {})
      @options = options
    end

    def store
      unless @store
        store_type = @options['store']['type']
        store_options = @options['store'].reject { |k, v| k == 'type' }
        @store = Store[store_type].new(store_options)
      end
      @store
    end

    def store=(store)
      @options['store'] = {'type' => store.type}.merge(store.options)
      @store = store
    end

    def save(filename)
      File.open(filename, 'w') do |f|
        f.write(@options.to_yaml)
      end
    end
  end
end
