module Keymaster
  module Store
    class SSH
      def initialize(options)
        @host = options[:host]
        @user = options[:user]
        @path = options[:path]
      end

      def read
        begin
          Net::SCP.download!(@host, @user, @path)
        rescue Net::SCP::Error
          nil
        end
      end

      def write(data)
        Net::SCP.upload!(@host, @user, StringIO.new(data), @path)
      end
    end
  end
end
