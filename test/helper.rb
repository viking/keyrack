require 'tempfile'
require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'test/unit'
require 'mocha'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'keymaster'

class Test::Unit::TestCase
  def fixture_path(name)
    File.dirname(__FILE__) + '/fixtures/' + name
  end

  def get_tmpname
    tmpname = Dir::Tmpname.create('keymaster') { }
    @tmpnames ||= []
    @tmpnames << tmpname
    tmpname
  end

  def teardown
    if @tmpnames
      @tmpnames.each { |t| File.unlink(t) if File.exist?(t) }
    end
  end
end
