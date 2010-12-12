class Keymaster
  module Store
    def self.[](name)
      case name
      when :filesystem then Filesystem
      end
    end
  end
end

require File.dirname(__FILE__) + '/store/filesystem'
