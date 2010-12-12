module Keymaster
  module Store
    class SSH
      def initialize(options)
        @host = options[:host]
        @user = options[:user]
        @path = options[:path]
      end

      def read
        Net::SCP.download!(@host, @user, @path)
      end

      def write(data)
        Net::SCP.upload!(@host, @user, StringIO.new(data), @path)
      end
    end
  end
end
