module Keymaster
  module Store
    class Filesystem
      def initialize(options)
        @path = File.expand_path(options[:path])
      end

      def read
        File.exist?(@path) ? File.read(@path) : nil
      end

      def write(data)
        File.open(@path, 'w') { |f| f.write(data) }
      end
    end
  end
end
