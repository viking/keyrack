require 'openssl'
require 'rubygems'
require 'bundler/setup'
require 'net/scp'

module Keymaster
end

require File.dirname(__FILE__) + '/keymaster/database'
require File.dirname(__FILE__) + '/keymaster/store'
