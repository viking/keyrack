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

      def test_get_new_entry_with_manual_password
        highline = mock('highline')
        HighLine.expects(:new).returns(highline)
        console = Console.new

        seq = sequence("new entry")
        highline.expects(:ask).with("Label: ").returns("Foo").in_sequence(seq)
        highline.expects(:ask).with("Username: ").returns("bar").in_sequence(seq)
        highline.expects(:agree).with("Generate password? [yn] ").returns(false).in_sequence(seq)
        highline.expects(:ask).with("Password: ").yields(mock { expects(:echo=).with(false) }).returns("baz").in_sequence(seq)
        highline.expects(:ask).with("Password (again): ").yields(mock { expects(:echo=).with(false) }).returns("bar").in_sequence(seq)
        highline.expects(:say).with("Passwords didn't match.  Try again!").in_sequence(seq)
        highline.expects(:ask).with("Password: ").yields(mock { expects(:echo=).with(false) }).returns("baz").in_sequence(seq)
        highline.expects(:ask).with("Password (again): ").yields(mock { expects(:echo=).with(false) }).returns("baz").in_sequence(seq)
        assert_equal({:site => "Foo", :username => "bar", :password => "baz"}, console.get_new_entry)
      end

      def test_get_new_entry_generated_password
        highline = mock('highline')
        HighLine.expects(:new).returns(highline)
        console = Console.new

        seq = sequence("new entry")
        highline.expects(:ask).with("Label: ").returns("Foo").in_sequence(seq)
        highline.expects(:ask).with("Username: ").returns("bar").in_sequence(seq)
        highline.expects(:agree).with("Generate password? [yn] ").returns(true).in_sequence(seq)
        Utils.expects(:generate_password).returns('foobar').in_sequence(seq)
        highline.expects(:agree).with("Generated 'foobar'.  Sound good? [yn] ").returns(false).in_sequence(seq)
        Utils.expects(:generate_password).returns('foobar').in_sequence(seq)
        highline.expects(:agree).with("Generated 'foobar'.  Sound good? [yn] ").returns(true).in_sequence(seq)
        assert_equal({:site => "Foo", :username => "bar", :password => "foobar"}, console.get_new_entry)
      end
    end
  end
end
