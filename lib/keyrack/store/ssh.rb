module Keyrack
  module Store
    class SSH
      def initialize(options)
        @host = options['host']
        @user = options['user']
        @path = options['path']
        @port = options['port'] || 22
      end

      def read
        begin
          result = nil
          Net::SSH.start(@host, @user, :port => @port) do |ssh|
            result = ssh.scp.download!(@path)
          end
          result
        rescue Net::SCP::Error
          nil
        end
      end

      def write(data)
        Net::SSH.start(@host, @user, :port => @port) do |ssh|
          ssh.scp.upload!(StringIO.new(data), @path)
        end
      end
    end
  end
end
