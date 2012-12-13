require 'helper'

class TestConsole < Test::Unit::TestCase
  def setup
    @twitter = twitter = stub('Twitter') do
      stubs(:usernames).returns(%w{username})
      stubs(:password_for).with('username').returns('password')
    end
    @google = google = stub('Google') do
      stubs(:usernames).returns(%w{username_1 username_2})
      stubs(:password_for).with('username_1').returns('password_1')
      stubs(:password_for).with('username_2').returns('password_2')
    end
    @top_group = stub('top group', :site_names => %w{Twitter Google}, :group_names => []) do
      stubs(:site).with('Twitter').returns(twitter)
      stubs(:site).with('Google').returns(google)
    end
    @highline = stub('highline')
    @highline.stubs(:color).with("Keyrack Main Menu", instance_of(Symbol)).
      returns("Keyrack Main Menu")
    @highline.stubs(:say)
    HighLine.expects(:new).returns(@highline)
    @console = Keyrack::UI::Console.new
  end

  test "select login from menu" do
    seq = sequence('say')
    @highline.expects(:say).with("=== Keyrack Main Menu ===")
    @highline.expects(:say).with(" 1. Twitter [username]")
    @highline.expects(:say).with(" 2. Google [username_1]")
    @highline.expects(:say).with(" 3. Google [username_2]")
    @highline.expects(:say).with("Mode: copy")
    @highline.expects(:say).with("Commands: [n]ew [d]elete [g]roup [m]ode [q]uit")

    question = mock('question')
    @highline.expects(:ask).yields(mock { expects(:in=).with(%w{n q m 1 2 3 d g}) }).returns('1')
    Clipboard.expects(:copy).with('password')
    @highline.expects(:say).with("The password has been copied to your clipboard.")
    assert_nil @console.menu(:group => @top_group, :at_top => true)
  end

  test "select entry from menu in print mode" do
    seq = sequence('say')
    @console.mode = :print
    @highline.expects(:say).with("=== Keyrack Main Menu ===")
    @highline.expects(:say).with(" 1. Twitter [username]")
    @highline.expects(:say).with(" 2. Google [username_1]")
    @highline.expects(:say).with(" 3. Google [username_2]")
    @highline.expects(:say).with("Mode: print")
    @highline.expects(:say).with("Commands: [n]ew [d]elete [g]roup [m]ode [q]uit")

    @highline.expects(:ask).yields(mock { expects(:in=).with(%w{n q m 1 2 3 d g}) }).returns('1')
    @highline.expects(:color).with('password', :cyan).returns('cyan[password]').in_sequence(seq)
    question = mock do
      expects(:echo=).with(false)
      if HighLine::SystemExtensions::CHARACTER_MODE != 'stty'
        expects(:character=).with(true)
        expects(:overwrite=).with(true)
      end
    end
    @highline.expects(:ask).
      with('Here you go: cyan[password]. Done? ').
      yields(question).
      returns('')

    assert_nil @console.menu(:group => @top_group, :at_top => true)
  end

  test "select new from menu" do
    # === Keyrack Main Menu ===
    #  1. Twitter [username]
    #  n. New entry
    #  d. Delete entry
    #  g. New group
    #  q. Quit

    @highline.expects(:ask).yields(mock { expects(:in=).with(%w{n q m 1 2 3 d g}) }).returns('n')
    assert_equal :new, @console.menu(:group => @top_group, :at_top => true)
  end

  test "select delete from menu" do
    # === Keyrack Main Menu ===
    #  1. Twitter [username]
    #  n. New entry
    #  d. Delete entry
    #  g. New group
    #  q. Quit

    question = mock('question')
    question.expects(:in=).with(%w{n q m 1 2 3 d g})
    @highline.expects(:ask).yields(question).returns('d')
    assert_equal :delete, @console.menu(:group => @top_group, :at_top => true)
  end

  test "select quit from menu" do
    # === Keyrack Main Menu ===
    #  1. Twitter [username]
    #  n. New entry
    #  d. Delete entry
    #  g. New group
    #  q. Quit

    @highline.expects(:ask).yields(mock { expects(:in=).with(%w{n q m 1 2 3 d g}) }).returns('q')
    assert_equal :quit, @console.menu(:group => @top_group, :at_top => true)
  end

  test "select quit from menu when database is dirty" do
    @highline.expects(:ask).yields(mock { expects(:in=).with(%w{n q m 1 2 3 d g s}) }).returns('q')
    @highline.expects(:agree).with("Really quit?  You have unsaved changes! [yn] ").returns(false)
    assert_equal nil, @console.menu(:group => @top_group, :at_top => true, :dirty => true)
  end

  test "select save from menu" do
    @highline.expects(:say).with { |string| string =~ /\[s\]ave/ }
    @highline.expects(:ask).yields(mock { expects(:in=).with(%w{n q m 1 2 3 d g s}) }).returns('s')
    assert_equal :save, @console.menu(:group => @top_group, :at_top => true, :dirty => true)
  end

  test "select group from menu" do
    @top_group.stubs(:group_names).returns(["Blargh"])
    blargh = stub('Blargh group')
    @top_group.stubs(:group).with('Blargh').returns(blargh)

    @highline.stubs(:color).with('Blargh', :green).returns('Blargh')
    @highline.expects(:say).with(" 1. Blargh")
    @highline.expects(:ask).yields(mock { expects(:in=).with(%w{n q m 1 2 3 4 d g}) }).returns('1')
    assert_equal({:group => blargh}, @console.menu(:group => @top_group, :at_top => true))
  end

  test "select entry from group menu" do
    facebook = stub('Facebook site', :usernames => %w{username}) do
      expects(:password_for).with('username').returns('password')
    end
    foo_group =
      stub('Foo group') do
        stubs(:name => 'Foo', :site_names => %w{Facebook}, :group_names => [])
        expects(:site).at_least(1).with('Facebook').returns(facebook)
      end

    @highline.expects(:color).with("Foo", :green).returns("Foo")
    @highline.expects(:say).with("===== Foo =====")
    @highline.expects(:say).with(" 1. Facebook [username]")
    @highline.expects(:say).with("Mode: copy")
    @highline.expects(:say).with("Commands: [n]ew [d]elete [g]roup [t]op [m]ode [q]uit")

    @highline.expects(:ask).yields(mock { expects(:in=).with(%w{n q m 1 d g t}) }).returns('1')
    Clipboard.expects(:copy).with('password')
    @highline.expects(:say).with("The password has been copied to your clipboard.")
    assert_nil @console.menu(:group => foo_group, :at_top => false)
  end

  test "get password" do
    question = mock('question')
    question.expects(:echo=).with(false)
    @highline.expects(:ask).with("Keyrack password: ").yields(question).returns("foobar")
    assert_equal "foobar", @console.get_password
  end

  test "get new entry with manual password" do
    seq = sequence("new entry")
    @highline.expects(:ask).with("Label: ").returns("Foo").in_sequence(seq)
    @highline.expects(:ask).with("Username: ").returns("bar").in_sequence(seq)
    @highline.expects(:agree).with("Generate password? [yn] ").returns(false).in_sequence(seq)
    @highline.expects(:ask).with("Password: ").yields(mock { expects(:echo=).with(false) }).returns("baz").in_sequence(seq)
    @highline.expects(:ask).with("Password (again): ").yields(mock { expects(:echo=).with(false) }).returns("bar").in_sequence(seq)
    @highline.expects(:say).with("Passwords didn't match. Try again!").in_sequence(seq)
    @highline.expects(:ask).with("Password: ").yields(mock { expects(:echo=).with(false) }).returns("baz").in_sequence(seq)
    @highline.expects(:ask).with("Password (again): ").yields(mock { expects(:echo=).with(false) }).returns("baz").in_sequence(seq)
    assert_equal({:site => "Foo", :username => "bar", :password => "baz"}, @console.get_new_entry)
  end

  test "get new entry with generated password" do
    seq = sequence("new entry")
    @highline.expects(:ask).with("Label: ").returns("Foo").in_sequence(seq)
    @highline.expects(:ask).with("Username: ").returns("bar").in_sequence(seq)
    @highline.expects(:agree).with("Generate password? [yn] ").returns(true).in_sequence(seq)
    Keyrack::Utils.expects(:generate_password).returns('foobar').in_sequence(seq)
    @highline.expects(:color).with('foobar', :cyan).returns('foobar').in_sequence(seq)
    @highline.expects(:agree).with("Generated foobar.  Sound good? [yn] ").returns(false).in_sequence(seq)
    Keyrack::Utils.expects(:generate_password).returns('foobar').in_sequence(seq)
    @highline.expects(:color).with('foobar', :cyan).returns('foobar').in_sequence(seq)
    @highline.expects(:agree).with("Generated foobar.  Sound good? [yn] ").returns(true).in_sequence(seq)
    assert_equal({:site => "Foo", :username => "bar", :password => "foobar"}, @console.get_new_entry)
  end

  test "display first time notice" do
    @highline.expects(:say).with("This looks like your first time using Keyrack.  I'll need to ask you a few questions first.")
    @console.display_first_time_notice
  end

  test "password setup" do
    seq = sequence("password setup")
    @highline.expects(:ask).with("New passphrase: ").yields(mock{expects(:echo=).with(false)}).returns('huge').in_sequence(seq)
    @highline.expects(:ask).with("Confirm passphrase: ").yields(mock{expects(:echo=).with(false)}).returns('small').in_sequence(seq)
    @highline.expects(:say).with("Passphrases didn't match.").in_sequence(seq)
    @highline.expects(:ask).with("New passphrase: ").yields(mock{expects(:echo=).with(false)}).returns('huge').in_sequence(seq)
    @highline.expects(:ask).with("Confirm passphrase: ").yields(mock{expects(:echo=).with(false)}).returns('huge').in_sequence(seq)
    assert_equal 'huge', @console.password_setup
  end

  test "store setup for filesystem" do
    @highline.expects(:choose).yields(mock {
      expects(:header=).with("Choose storage type")
      expects(:choices).with("filesystem", "ssh")
    }).returns("filesystem")

    expected = {'type' => 'filesystem', 'path' => 'database'}
    assert_equal expected, @console.store_setup
  end

  test "store setup for ssh" do
    seq = sequence("store setup")
    @highline.expects(:choose).yields(mock {
      expects(:header=).with("Choose storage type")
      expects(:choices).with("filesystem", "ssh")
    }).returns("ssh").in_sequence(seq)
    @highline.expects(:ask).with("Host: ").returns("example.com").in_sequence(seq)
    @highline.expects(:ask).with("User: ").returns("dudeguy").in_sequence(seq)
    @highline.expects(:ask).with("Remote path: ").returns(".keyrack/database").in_sequence(seq)

    expected = {'type' => 'ssh', 'host' => 'example.com', 'user' => 'dudeguy', 'path' => '.keyrack/database'}
    assert_equal expected, @console.store_setup
  end

  test "get new group" do
    @highline.expects(:ask).with("Group: ").yields(mock {
      expects(:validate=).with(/^\w[\w\s]*$/)
    }).returns("Foo")
    assert_equal('Foo', @console.get_new_group)
  end

  test "delete entry" do
    seq = sequence("deleting")
    @highline.expects(:say).with("Choose entry to delete:").in_sequence(seq)
    @highline.expects(:say).with(" 1. Twitter [username]").in_sequence(seq)
    @highline.expects(:say).with(" 2. Google [username_1]").in_sequence(seq)
    @highline.expects(:say).with(" 3. Google [username_2]").in_sequence(seq)
    @highline.expects(:say).with(" c. Cancel").in_sequence(seq)
    @highline.expects(:ask).yields(mock {
      expects(:in=).with(%w{c 1 2 3})
    }).returns('1').in_sequence(seq)
    @highline.expects(:color).with("Twitter [username]", :red).returns("Twitter").in_sequence(seq)
    @highline.expects(:agree).with("You're about to delete Twitter.  Are you sure? [yn] ").returns(true).in_sequence(seq)
    assert_equal({:site => 'Twitter', :username => 'username'}, @console.delete_entry(@top_group))
  end

  test "delete one entry from site with multiple entries" do
    seq = sequence("deleting")
    @highline.expects(:say).with("Choose entry to delete:").in_sequence(seq)
    @highline.expects(:say).with(" 1. Twitter [username]").in_sequence(seq)
    @highline.expects(:say).with(" 2. Google [username_1]").in_sequence(seq)
    @highline.expects(:say).with(" 3. Google [username_2]").in_sequence(seq)
    @highline.expects(:say).with(" c. Cancel").in_sequence(seq)
    @highline.expects(:ask).yields(mock {
      expects(:in=).with(%w{c 1 2 3})
    }).returns('3').in_sequence(seq)
    @highline.expects(:color).with("Google [username_2]", :red).returns("Google [username_2]").in_sequence(seq)
    @highline.expects(:agree).with("You're about to delete Google [username_2].  Are you sure? [yn] ").returns(true).in_sequence(seq)
    assert_equal({:site => "Google", :username => "username_2"}, @console.delete_entry(@top_group))
  end

  test "delete entry in subgroup" do
    @top_group.stubs(:group_names).returns(%w{Social})

    quora = stub('Quora site', :usernames => %w{username})
    foursquare = stub('Foursquare site', :usernames => %w{username})
    social_group = stub('Social group') do
      stubs(:site_names => %w{Quora Foursquare}, :group_names => [])
      stubs(:site).with('Quora').returns(quora)
      stubs(:site).with('Foursquare').returns(foursquare)
    end
    @top_group.stubs(:group).with('Social').returns(social_group)

    seq = sequence("deleting")
    @highline.expects(:say).with("Choose entry to delete:").in_sequence(seq)
    @highline.expects(:say).with(" 1. Quora [username]").in_sequence(seq)
    @highline.expects(:say).with(" 2. Foursquare [username]").in_sequence(seq)
    @highline.expects(:say).with(" c. Cancel").in_sequence(seq)
    @highline.expects(:ask).yields(mock {
      expects(:in=).with(%w{c 1 2})
    }).returns('2').in_sequence(seq)
    @highline.expects(:color).with("Foursquare [username]", :red).returns("Foursquare [username]").in_sequence(seq)
    @highline.expects(:agree).with("You're about to delete Foursquare [username].  Are you sure? [yn] ").returns(true).in_sequence(seq)
    assert_equal({:site => "Foursquare", :username => "username"}, @console.delete_entry(social_group))
  end

  test "switching mode from menu" do
    @console.mode = :copy

    @highline.expects(:ask).yields(mock { expects(:in=).with(%w{n q m 1 2 3 d g}) }).returns('m')
    assert_nil @console.menu(:group => @top_group, :at_top => true)
    assert_equal :print, @console.mode
  end

  test "confirm overwrite entry" do
    @highline.expects(:color).with("Twitter [username]", :cyan).returns("Twitter [username]")
    @highline.expects(:agree).with("There's already an entry for: Twitter [username]. Do you want to overwrite it? [yn] ").returns(true)
    assert_equal true, @console.confirm_overwrite_entry('Twitter', 'username')
  end

  test "top command" do
    foo_group = stub('Foo group', :name => 'Foo', :site_names => [], :group_names => [])
    @highline.stubs(:color).with('Foo', instance_of(Symbol)).returns('Foo')
    @highline.expects(:say).with("Commands: [n]ew [g]roup [t]op [m]ode [q]uit")
    @highline.expects(:ask).yields(mock { expects(:in=).with(%w{n q m g t}) }).returns('t')
    assert_equal :top, @console.menu(:group => foo_group, :at_top => false)
  end

  test "up command" do
    foo_group = stub('Foo group', :name => 'Foo', :site_names => [], :group_names => [])
    @highline.stubs(:color).with('Foo', instance_of(Symbol)).returns('Foo')
    @highline.expects(:say).with("Commands: [n]ew [g]roup [u]p [t]op [m]ode [q]uit")
    @highline.expects(:ask).yields(mock { expects(:in=).with(%w{n q m g u t}) }).returns('u')
    assert_equal :up, @console.menu(:group => foo_group, :at_top => false, :enable_up => true)
  end

  test "invalid password" do
    @highline.expects(:say).with("Invalid password.")
    @console.display_invalid_password_notice
  end
end
