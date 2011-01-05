require 'helper'

module Keyrack
  module UI
    class TestConsole < Test::Unit::TestCase
      def setup
        @database = stub('database', :sites => %w{Twitter}, :groups => [], :dirty? => false) do
          stubs(:get).with('Twitter', {}).returns({
            :username => 'username', :password => 'password'
          })
        end
        @highline = mock('highline')
        @highline.stubs(:color).with("Keyrack Main Menu", :yellow).returns("yellowKeyrack Main Menu")
        HighLine.expects(:new).returns(@highline)
        @console = Console.new
      end

      def test_select_entry_from_menu
        @console.database = @database
        @highline.expects(:say).with("=== yellowKeyrack Main Menu ===")
        @highline.expects(:say).with(" 1. Twitter [username]")
        @highline.expects(:say).with(" n. New entry")
        @highline.expects(:say).with(" g. New group")
        @highline.expects(:say).with(" q. Quit")

        question = mock('question')
        question.expects(:in=).with(%w{n q 1 g})
        @highline.expects(:ask).yields(question).returns('1')
        @console.expects(:Copier).with('password')
        @highline.expects(:say).with("The password has been copied to your clipboard.")
        assert_nil @console.menu
      end

      def test_select_new_from_menu
        @console.database = @database

        @highline.expects(:say).with("=== yellowKeyrack Main Menu ===")
        @highline.expects(:say).with(" 1. Twitter [username]")
        @highline.expects(:say).with(" n. New entry")
        @highline.expects(:say).with(" g. New group")
        @highline.expects(:say).with(" q. Quit")

        question = mock('question')
        question.expects(:in=).with(%w{n q 1 g})
        @highline.expects(:ask).yields(question).returns('n')
        assert_equal :new, @console.menu
      end

      def test_select_quit_from_menu
        @console.database = @database

        @highline.expects(:say).with("=== yellowKeyrack Main Menu ===")
        @highline.expects(:say).with(" 1. Twitter [username]")
        @highline.expects(:say).with(" n. New entry")
        @highline.expects(:say).with(" g. New group")
        @highline.expects(:say).with(" q. Quit")

        question = mock('question')
        question.expects(:in=).with(%w{n q 1 g})
        @highline.expects(:ask).yields(question).returns('q')
        assert_equal :quit, @console.menu
      end

      def test_select_quit_from_menu_when_database_is_dirty
        @console.database = @database
        @database.stubs(:dirty?).returns(true)

        @highline.expects(:say).with("=== yellowKeyrack Main Menu ===")
        @highline.expects(:say).with(" 1. Twitter [username]")
        @highline.expects(:say).with(" n. New entry")
        @highline.expects(:say).with(" g. New group")
        @highline.expects(:say).with(" s. Save")
        @highline.expects(:say).with(" q. Quit")

        question = mock('question', :in= => nil)
        @highline.expects(:ask).yields(question).returns('q')
        @highline.expects(:agree).with("Really quit?  You have unsaved changes! [yn] ").returns(false)
        assert_equal nil, @console.menu
      end

      def test_select_save_from_menu
        @console.database = @database
        @database.stubs(:dirty?).returns(true)

        @highline.expects(:say).with("=== yellowKeyrack Main Menu ===")
        @highline.expects(:say).with(" 1. Twitter [username]")
        @highline.expects(:say).with(" n. New entry")
        @highline.expects(:say).with(" g. New group")
        @highline.expects(:say).with(" s. Save")
        @highline.expects(:say).with(" q. Quit")

        question = mock('question')
        question.expects(:in=).with(%w{n q 1 g s})
        @highline.expects(:ask).yields(question).returns('s')
        assert_equal :save, @console.menu
      end

      def test_select_group_from_menu
        @console.database = @database
        @database.stubs(:groups).returns(["Blargh"])

        @highline.expects(:say).with("=== yellowKeyrack Main Menu ===")
        @highline.expects(:color).with('Blargh', :green).returns('greenBlargh')
        @highline.expects(:say).with(" 1. greenBlargh")
        @highline.expects(:say).with(" 2. Twitter [username]")
        @highline.expects(:say).with(" n. New entry")
        @highline.expects(:say).with(" g. New group")
        @highline.expects(:say).with(" q. Quit")

        question = mock('question')
        question.expects(:in=).with(%w{n q 1 2 g})
        @highline.expects(:ask).yields(question).returns('1')
        assert_equal({:group => 'Blargh'}, @console.menu)
      end

      def test_select_entry_from_group_menu
        @console.database = @database
        @database.expects(:sites).with(:group => "Foo").returns(["Facebook"])
        @database.expects(:get).with('Facebook', :group => "Foo").returns({:username => 'username', :password => 'password'})

        @highline.expects(:color).with("Foo", :green).returns("greenFoo")
        @highline.expects(:say).with("===== greenFoo =====")
        @highline.expects(:say).with(" 1. Facebook [username]")
        @highline.expects(:say).with(" n. New entry")
        @highline.expects(:say).with(" t. Top level menu")
        @highline.expects(:say).with(" q. Quit")

        question = mock('question')
        question.expects(:in=).with(%w{n q 1 t})
        @highline.expects(:ask).yields(question).returns('1')
        @console.expects(:Copier).with('password')
        @highline.expects(:say).with("The password has been copied to your clipboard.")
        assert_nil @console.menu(:group => 'Foo')
      end

      def test_get_password
        question = mock('question')
        question.expects(:echo=).with(false)
        @highline.expects(:ask).with("Keyrack password: ").yields(question).returns("foobar")
        assert_equal "foobar", @console.get_password
      end

      def test_get_new_entry_with_manual_password
        seq = sequence("new entry")
        @highline.expects(:ask).with("Label: ").returns("Foo").in_sequence(seq)
        @highline.expects(:ask).with("Username: ").returns("bar").in_sequence(seq)
        @highline.expects(:agree).with("Generate password? [yn] ").returns(false).in_sequence(seq)
        @highline.expects(:ask).with("Password: ").yields(mock { expects(:echo=).with(false) }).returns("baz").in_sequence(seq)
        @highline.expects(:ask).with("Password (again): ").yields(mock { expects(:echo=).with(false) }).returns("bar").in_sequence(seq)
        @highline.expects(:say).with("Passwords didn't match.  Try again!").in_sequence(seq)
        @highline.expects(:ask).with("Password: ").yields(mock { expects(:echo=).with(false) }).returns("baz").in_sequence(seq)
        @highline.expects(:ask).with("Password (again): ").yields(mock { expects(:echo=).with(false) }).returns("baz").in_sequence(seq)
        assert_equal({:site => "Foo", :username => "bar", :password => "baz"}, @console.get_new_entry)
      end

      def test_get_new_entry_generated_password
        seq = sequence("new entry")
        @highline.expects(:ask).with("Label: ").returns("Foo").in_sequence(seq)
        @highline.expects(:ask).with("Username: ").returns("bar").in_sequence(seq)
        @highline.expects(:agree).with("Generate password? [yn] ").returns(true).in_sequence(seq)
        Utils.expects(:generate_password).returns('foobar').in_sequence(seq)
        @highline.expects(:color).with('foobar', :blue).returns('bluefoobar').in_sequence(seq)
        @highline.expects(:agree).with("Generated bluefoobar.  Sound good? [yn] ").returns(false).in_sequence(seq)
        Utils.expects(:generate_password).returns('foobar').in_sequence(seq)
        @highline.expects(:color).with('foobar', :blue).returns('bluefoobar').in_sequence(seq)
        @highline.expects(:agree).with("Generated bluefoobar.  Sound good? [yn] ").returns(true).in_sequence(seq)
        assert_equal({:site => "Foo", :username => "bar", :password => "foobar"}, @console.get_new_entry)
      end

      def test_display_first_time_notice
        @highline.expects(:say).with("This looks like your first time using Keyrack.  I'll need to ask you a few questions first.")
        @console.display_first_time_notice
      end

      def test_rsa_setup
        seq = sequence("rsa setup")
        @highline.expects(:ask).with("New passphrase: ").yields(mock{expects(:echo=).with(false)}).returns('huge').in_sequence(seq)
        @highline.expects(:ask).with("Confirm passphrase: ").yields(mock{expects(:echo=).with(false)}).returns('small').in_sequence(seq)
        @highline.expects(:say).with("Passphrases didn't match.").in_sequence(seq)
        @highline.expects(:ask).with("New passphrase: ").yields(mock{expects(:echo=).with(false)}).returns('huge').in_sequence(seq)
        @highline.expects(:ask).with("Confirm passphrase: ").yields(mock{expects(:echo=).with(false)}).returns('huge').in_sequence(seq)
        expected = {'password' => 'huge', 'path' => 'rsa'}
        assert_equal expected, @console.rsa_setup
      end

      def test_store_setup_for_filesystem
        @highline.expects(:choose).yields(mock {
          expects(:header=).with("Choose storage type:")
          expects(:choices).with("filesystem", "ssh")
        }).returns("filesystem")

        expected = {'type' => 'filesystem', 'path' => 'database'}
        assert_equal expected, @console.store_setup
      end

      def test_store_setup_for_ssh
        seq = sequence("store setup")
        @highline.expects(:choose).yields(mock {
          expects(:header=).with("Choose storage type:")
          expects(:choices).with("filesystem", "ssh")
        }).returns("ssh").in_sequence(seq)
        @highline.expects(:ask).with("Host: ").returns("example.com").in_sequence(seq)
        @highline.expects(:ask).with("User: ").returns("dudeguy").in_sequence(seq)
        @highline.expects(:ask).with("Remote path: ").returns(".keyrack/database").in_sequence(seq)

        expected = {'type' => 'ssh', 'host' => 'example.com', 'user' => 'dudeguy', 'path' => '.keyrack/database'}
        assert_equal expected, @console.store_setup
      end

      def test_get_new_group
        seq = sequence("new group")
        @highline.expects(:ask).with("Group: ").yields(mock {
          expects(:validate=).with(/^\w[\w\s]*$/)
        }).returns("Foo").in_sequence(seq)
        assert_equal({:group => "Foo"}, @console.get_new_group)
      end
    end
  end
end
