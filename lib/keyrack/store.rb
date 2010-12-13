module Keyrack
  module Store
    def self.[](name)
      case name
      when :filesystem, 'filesystem' then Filesystem
      when :ssh, 'ssh' then SSH
      end
    end
  end
end

require File.dirname(__FILE__) + '/store/filesystem'
require File.dirname(__FILE__) + '/store/ssh'
