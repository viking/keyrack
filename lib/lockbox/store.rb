module Lockbox
  module Store
    def self.[](name)
      case name
      when :filesystem then Filesystem
      when :ssh then SSH
      end
    end
  end
end

require File.dirname(__FILE__) + '/store/filesystem'
require File.dirname(__FILE__) + '/store/ssh'
