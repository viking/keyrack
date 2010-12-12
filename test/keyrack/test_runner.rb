require 'helper'

module Keyrack
  class TestRunner < Test::Unit::TestCase
    def test_console
      config = {
        :store => { :type => :filesystem, :path => 'foobar' },
        :key => fixture_path('id_rsa')
      }
      config_path = get_tmpname
      File.open(config_path, 'w') { |f| f.print(config.to_yaml) }

      console = mock('console')
      UI::Console.expects(:new).returns(console)
      database = mock('database')

      seq = sequence('ui sequence')
      console.expects(:get_password).returns('secret').in_sequence(seq)
      Database.expects(:new).with(config.merge(:password => 'secret')).returns(database).in_sequence(seq)
      console.expects(:database=).with(database).in_sequence(seq)
      console.expects(:menu).returns(:new).in_sequence(seq)
      console.expects(:get_new_entry).returns({:site => "Foo", :username => "bar", :password => "baz"}).in_sequence(seq)
      database.expects(:add).with("Foo", "bar", "baz")
      console.expects(:menu).returns(nil).in_sequence(seq)
      console.expects(:menu).returns(:save).in_sequence(seq)
      database.expects(:save).in_sequence(seq)
      console.expects(:menu).returns(:quit).in_sequence(seq)

      runner = Runner.new(["-c", config_path])
    end
  end
end
