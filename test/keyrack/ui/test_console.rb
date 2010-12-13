require 'helper'

module Keyrack
  module UI
    class TestConsole < Test::Unit::TestCase
      def setup
        @path = get_tmpname
        @database = Database.new({
          'store' => { 'type' => 'filesystem', 'path' => @path },
          'key' => fixture_path('id_rsa'),
          'password' => 'secret'
        })
        @database.add('Twitter', 'username', 'password')
        @database.save
      end

      def test_select_entry_from_menu
        highline = mock('highline')
        HighLine.expects(:new).returns(highline)
        console = Console.new
        console.database = @database

        highline.expects(:say).with(" 1. Twitter [username]")
        highline.expects(:say).with(" n. Add new")
        highline.expects(:say).with(" s. Save")
        highline.expects(:say).with(" q. Quit")

        question = mock('question')
        question.expects(:in=).with(%w{n s q 1})
        highline.expects(:ask).yields(question).returns('1')
        Clipboard.expects(:copy).with('password')
        highline.expects(:say).with("The password has been copied to your clipboard.")
        assert_nil console.menu
      end

      def test_select_new_from_menu
        highline = mock('highline')
        HighLine.expects(:new).returns(highline)
        console = Console.new
        console.database = @database

        highline.expects(:say).with(" 1. Twitter [username]")
        highline.expects(:say).with(" n. Add new")
        highline.expects(:say).with(" s. Save")
        highline.expects(:say).with(" q. Quit")

        question = mock('question')
        question.expects(:in=).with(%w{n s q 1})
        highline.expects(:ask).yields(question).returns('n')
        assert_equal :new, console.menu
      end

      def test_select_quit_from_menu
        highline = mock('highline')
        HighLine.expects(:new).returns(highline)
        console = Console.new
        console.database = @database

        highline.expects(:say).with(" 1. Twitter [username]")
        highline.expects(:say).with(" n. Add new")
        highline.expects(:say).with(" s. Save")
        highline.expects(:say).with(" q. Quit")

        question = mock('question')
        question.expects(:in=).with(%w{n s q 1})
        highline.expects(:ask).yields(question).returns('q')
        assert_equal :quit, console.menu
      end

      def test_select_save_from_menu
        highline = mock('highline')
        HighLine.expects(:new).returns(highline)
        console = Console.new
        console.database = @database

        highline.expects(:say).with(" 1. Twitter [username]")
        highline.expects(:say).with(" n. Add new")
        highline.expects(:say).with(" s. Save")
        highline.expects(:say).with(" q. Quit")

        question = mock('question')
        question.expects(:in=).with(%w{n s q 1})
        highline.expects(:ask).yields(question).returns('s')
        assert_equal :save, console.menu
      end

      def test_get_password
        highline = mock('highline')
        HighLine.expects(:new).returns(highline)
        console = Console.new

        question = mock('question')
        question.expects(:echo=).with(false)
        highline.expects(:ask).with("Keyrack password: ").yields(question).returns("foobar")
        assert_equal "foobar", console.get_password
      end

      def test_get_new_entry
        highline = mock('highline')
        HighLine.expects(:new).returns(highline)
        console = Console.new

        highline.expects(:ask).with("Site:     ").returns("Foo")
        highline.expects(:ask).with("Username: ").returns("bar")
        highline.expects(:ask).with("Password: ").returns("baz")
        assert_equal({:site => "Foo", :username => "bar", :password => "baz"}, console.get_new_entry)
      end
    end
  end
end
