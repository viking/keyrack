require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'tempfile'
require 'fileutils'
require 'pty'
require 'yaml'
require 'test/unit/assertions'

World(Test::Unit::Assertions)
