require 'helper'

class TestRunner < Test::Unit::TestCase
  def setup
    @console = stub('console', {
      :get_password => 'secret',
      :get_new_entry => {:site => "Foo", :username => "bar", :password => "baz"}
    })
    Keyrack::UI::Console.stubs(:new).returns(@console)
    @top_group = stub('top group', :sites => [], :group_names => [])
    @database = stub('database', :top_group => @top_group)
    Keyrack::Database.stubs(:new).returns(@database)

    @store = stub('filesystem store')
    Keyrack::Store::Filesystem.stubs(:new).with(instance_of(Hash)).returns(@store)
    Keyrack::Database.stubs(:new).with('secret', @store).returns(@database)

    @keyrack_dir = get_tmpname
    Dir.mkdir(@keyrack_dir)

    @menu_options = {
      :group => @top_group, :at_top => true,
      :enable_up => false, :dirty => false, :open => false
    }
  end

  DEFAULT_CONFIG = {
    'store' => {
      'type' => 'filesystem',
      'path' => 'foo.db'
    }
  }

  def setup_config(config = {})
    config = DEFAULT_CONFIG.merge(config)
    File.open(File.join(@keyrack_dir, 'config.yml'), 'w') { |f| f.print(config.to_yaml) }
  end

  test "console startup for existing database" do
    setup_config

    store = mock('filesystem store')
    Keyrack::UI::Console.expects(:new).returns(@console)

    seq = SequenceHelper.new('ui sequence')
    seq << @console.expects(:get_password).returns('secret')
    seq << Keyrack::Store::Filesystem.expects(:new).with('path' => File.join(@keyrack_dir, 'foo.db')).returns(store)
    seq << Keyrack::Database.expects(:new).with('secret', store).returns(@database)
    seq << @database.expects(:dirty?).returns(false)
    seq << @console.expects(:menu).with(@menu_options).returns(:quit)

    runner = Keyrack::Runner.new(["-d", @keyrack_dir])
  end

  test "console startup for existing database with wrong password" do
    setup_config

    store = mock('filesystem store')
    Keyrack::UI::Console.expects(:new).returns(@console)

    seq = SequenceHelper.new('ui sequence')
    seq << @console.expects(:get_password).returns('secret')
    seq << Keyrack::Store::Filesystem.expects(:new).with('path' => File.join(@keyrack_dir, 'foo.db')).returns(store)
    seq << Keyrack::Database.expects(:new).with('secret', store).raises(Scrypty::IncorrectPasswordError)
    seq << @console.expects(:display_invalid_password_notice)

    runner = Keyrack::Runner.new(["-d", @keyrack_dir])
  end

  test "opening and collapsing" do
    setup_config

    seq = SequenceHelper.new('ui sequence')
    seq << @database.expects(:dirty?).returns(false)
    seq << @console.expects(:menu).with(@menu_options).returns(:open)
    seq << @database.expects(:dirty?).returns(false)
    seq << @console.expects(:menu).with(@menu_options.merge(:open => true)).returns(:collapse)
    seq << @database.expects(:dirty?).returns(false)
    seq << @console.expects(:menu).with(@menu_options).returns(:quit)

    runner = Keyrack::Runner.new(["-d", @keyrack_dir])
  end

  test "add site" do
    setup_config

    seq = SequenceHelper.new('ui sequence')
    seq << @database.expects(:dirty?).returns(false)
    seq << @console.expects(:menu).with(@menu_options).returns(:new)
    seq << @console.expects(:get_new_entry).returns({:site => "Foo", :username => "bar", :password => "baz"})

    new_site = stub('site')
    seq << Keyrack::Site.expects(:new).with('Foo', 'bar', 'baz').returns(new_site)
    seq << @top_group.expects(:add_site).with(new_site)
    seq << @database.expects(:dirty?).returns(true)
    seq << @console.expects(:menu).with(@menu_options.merge(:dirty => true)).returns(:quit)

    runner = Keyrack::Runner.new(["-d", @keyrack_dir])
  end

  test "add existing site" do
    setup_config

    seq = SequenceHelper.new('ui sequence')
    foo_site = stub('Foo site', {
      :name => 'Foo',
      :username => 'bar',
      :password => 'baz'
    })
    new_site = stub('new Foo site', {
      :name => 'Foo',
      :username => 'bar',
      :password => 'junk'
    })
    foo_site.stubs(:==).with(new_site).returns(true)

    seq << @database.expects(:dirty?).returns(true)
    seq << @console.expects(:menu).with(@menu_options.merge(:dirty => true)).returns(:new)
    seq << @console.expects(:get_new_entry).returns({:site => "Foo", :username => "bar", :password => "junk"})
    seq << Keyrack::Site.expects(:new).with('Foo', 'bar', 'junk').returns(new_site)
    seq << @top_group.expects(:sites).returns([foo_site])
    seq << @console.expects(:confirm_overwrite_entry).with(foo_site).returns(true)
    seq << foo_site.expects(:password=).with('junk')

    seq << @database.expects(:dirty?).returns(true)
    seq << @console.expects(:menu).with(@menu_options.merge(:dirty => true)).returns(:quit)

    runner = Keyrack::Runner.new(["-d", @keyrack_dir])
  end

  test "cancel adding entry" do
    setup_config

    seq = SequenceHelper.new('ui sequence')
    seq << @database.expects(:dirty?).returns(false)
    seq << @console.expects(:menu).with(@menu_options).returns(:new)
    seq << @console.expects(:get_new_entry).returns(nil)

    seq << @database.expects(:dirty?).returns(false)
    seq << @console.expects(:menu).with(@menu_options).returns(:quit)

    runner = Keyrack::Runner.new(["-d", @keyrack_dir])
  end

  test "canceling edit selection" do
    setup_config

    seq = SequenceHelper.new('ui sequence')
    seq << @database.expects(:dirty?).returns(false)
    seq << @console.expects(:menu).with(@menu_options).returns(:edit)
    seq << @console.expects(:choose_entry_to_edit).with(@top_group).returns(nil)

    seq << @database.expects(:dirty?).returns(false)
    seq << @console.expects(:menu).with(@menu_options).returns(:quit)

    runner = Keyrack::Runner.new(["-d", @keyrack_dir])
  end

  test "changing username" do
    setup_config

    foo_site = stub('Foo site', :username => 'bar')
    seq = SequenceHelper.new('ui sequence')
    seq << @database.expects(:dirty?).returns(false)
    seq << @console.expects(:menu).with(@menu_options).returns(:edit)
    seq << @console.expects(:choose_entry_to_edit).with(@top_group).returns({:site => foo_site})
    seq << @console.expects(:edit_entry).with(foo_site).returns(:change_username)
    seq << @console.expects(:change_username).with('bar').returns('junk')
    seq << foo_site.expects(:username=).with('junk')
    seq << @console.expects(:edit_entry).with(foo_site).returns(nil)

    seq << @database.expects(:dirty?).returns(true)
    seq << @console.expects(:menu).with(@menu_options.merge(:dirty => true)).returns(:quit)

    runner = Keyrack::Runner.new(["-d", @keyrack_dir])
  end

  test "cancel changing username" do
    setup_config

    foo_site = stub('Foo site', :username => 'bar')

    seq = SequenceHelper.new('ui sequence')
    seq << @database.expects(:dirty?).returns(false)
    seq << @console.expects(:menu).with(@menu_options).returns(:edit)
    seq << @console.expects(:choose_entry_to_edit).with(@top_group).returns({:site => foo_site})
    seq << @console.expects(:edit_entry).with(foo_site).returns(:change_username)
    seq << @console.expects(:change_username).with('bar').returns(nil)
    seq << @console.expects(:edit_entry).with(foo_site).returns(nil)

    seq << @database.expects(:dirty?).returns(false)
    seq << @console.expects(:menu).with(@menu_options).returns(:quit)

    runner = Keyrack::Runner.new(["-d", @keyrack_dir])
  end

  test "changing password" do
    setup_config

    foo_site = stub('Foo site')

    seq = SequenceHelper.new('ui sequence')
    seq << @database.expects(:dirty?).returns(false)
    seq << @console.expects(:menu).with(@menu_options).returns(:edit)
    seq << @console.expects(:choose_entry_to_edit).with(@top_group).returns({:site => foo_site})
    seq << @console.expects(:edit_entry).with(foo_site).returns(:change_password)
    seq << @console.expects(:get_new_password).returns('secret')
    seq << foo_site.expects(:password=).with('secret')
    seq << @console.expects(:edit_entry).with(foo_site).returns(nil)

    seq << @database.expects(:dirty?).returns(true)
    seq << @console.expects(:menu).with(@menu_options.merge(:dirty => true)).returns(:quit)

    runner = Keyrack::Runner.new(["-d", @keyrack_dir])
  end

  test "cancel changing password" do
    setup_config

    foo_site = stub('Foo site')

    seq = SequenceHelper.new('ui sequence')
    seq << @database.expects(:dirty?).returns(false)
    seq << @console.expects(:menu).with(@menu_options).returns(:edit)
    seq << @console.expects(:choose_entry_to_edit).with(@top_group).returns({:site => foo_site})
    seq << @console.expects(:edit_entry).with(foo_site).returns(:change_password)
    seq << @console.expects(:get_new_password).returns(nil)
    seq << @console.expects(:edit_entry).with(foo_site).returns(nil)

    seq << @database.expects(:dirty?).returns(false)
    seq << @console.expects(:menu).with(@menu_options).returns(:quit)

    runner = Keyrack::Runner.new(["-d", @keyrack_dir])
  end

  test "delete entry" do
    setup_config

    foo_site = stub('Foo site', :name => 'Foo', :username => 'bar')

    seq = SequenceHelper.new('ui sequence')
    seq << @database.expects(:dirty?).returns(false)
    seq << @console.expects(:menu).with(@menu_options).returns(:edit)
    seq << @console.expects(:choose_entry_to_edit).with(@top_group).returns({:site => foo_site})
    seq << @console.expects(:edit_entry).with(foo_site).returns(:delete)
    seq << @console.expects(:confirm_delete_entry).with(foo_site).returns(true)
    seq << @top_group.expects(:remove_site).with(foo_site)

    seq << @database.expects(:dirty?).returns(true)
    seq << @console.expects(:menu).with(@menu_options.merge(:dirty => true)).returns(:quit)

    runner = Keyrack::Runner.new(["-d", @keyrack_dir])
  end

  test "cancel delete entry" do
    setup_config

    foo_site = stub('Foo site')

    seq = SequenceHelper.new('ui sequence')
    seq << @database.expects(:dirty?).returns(false)
    seq << @console.expects(:menu).with(@menu_options).returns(:edit)
    seq << @console.expects(:choose_entry_to_edit).with(@top_group).returns({:site => foo_site})
    seq << @console.expects(:edit_entry).with(foo_site).returns(:delete)
    seq << @console.expects(:confirm_delete_entry).with(foo_site).returns(false)
    seq << @console.expects(:edit_entry).with(foo_site).returns(nil)

    seq << @database.expects(:dirty?).returns(false)
    seq << @console.expects(:menu).with(@menu_options).returns(:quit)

    runner = Keyrack::Runner.new(["-d", @keyrack_dir])
  end

  test "creating new group" do
    setup_config

    seq = SequenceHelper.new("ui sequence")
    seq << @database.expects(:dirty?).returns(false)
    seq << @console.expects(:menu).with(@menu_options).returns(:new_group)
    seq << @console.expects(:get_new_group).returns('Foo')

    new_group = stub('Foo group', :site_names => [], :group_names => [])
    seq << Keyrack::Group.expects(:new).with('Foo').returns(new_group)
    seq << @top_group.expects(:add_group).with(new_group)

    seq << @database.expects(:dirty?).returns(true)
    seq << @console.expects(:menu).
      with(@menu_options.merge(:group => new_group, :at_top => false, :dirty => true)).
      returns(:quit)

    runner = Keyrack::Runner.new(["-d", @keyrack_dir])
  end

  test "creating new subgroup" do
    setup_config

    seq = SequenceHelper.new("ui sequence")
    seq << @database.expects(:dirty?).returns(false)
    seq << @console.expects(:menu).with(@menu_options).returns(:new_group)
    seq << @console.expects(:get_new_group).returns('Foo')

    foo_group = stub('Foo group', :site_names => [], :group_names => [])
    seq << Keyrack::Group.expects(:new).with('Foo').returns(foo_group)
    seq << @top_group.expects(:add_group).with(foo_group)

    seq << @database.expects(:dirty?).returns(true)
    seq << @console.expects(:menu).
      with(@menu_options.merge(:group => foo_group, :at_top => false, :dirty => true)).
      returns(:new_group)
    seq << @console.expects(:get_new_group).returns('Bar')

    bar_group = stub('Bar group', :site_names => [], :group_names => [])
    seq << Keyrack::Group.expects(:new).with('Bar').returns(bar_group)
    seq << foo_group.expects(:add_group).with(bar_group)

    seq << @database.expects(:dirty?).returns(true)
    seq << @console.expects(:menu).
      with(@menu_options.merge(:group => bar_group, :at_top => false, :dirty => true, :enable_up => true)).
      returns(:quit)

    runner = Keyrack::Runner.new(["-d", @keyrack_dir])
  end

  test "save" do
    setup_config

    seq = SequenceHelper.new("ui sequence")
    seq << @database.expects(:dirty?).returns(true)
    seq << @console.expects(:menu).with(@menu_options.merge(:dirty => true)).returns(:save)
    seq << @console.expects(:get_password).returns('secret')
    seq << @database.expects(:save).with('secret').returns(true)

    seq << @database.expects(:dirty?).returns(false)
    seq << @console.expects(:menu).with(@menu_options).returns(:quit)

    runner = Keyrack::Runner.new(["-d", @keyrack_dir])
  end

  test "save with invalid password" do
    setup_config

    seq = SequenceHelper.new("ui sequence")
    seq << @database.expects(:dirty?).returns(true)
    seq << @console.expects(:menu).with(@menu_options.merge(:dirty => true)).returns(:save)
    seq << @console.expects(:get_password).returns('secret')
    seq << @database.expects(:save).with('secret').returns(false)
    seq << @console.expects(:display_invalid_password_notice)
    seq << @database.expects(:dirty?).returns(true)
    seq << @console.expects(:menu).with(@menu_options.merge(:dirty => true)).returns(:quit)

    runner = Keyrack::Runner.new(["-d", @keyrack_dir])
  end

  test "selecting group" do
    setup_config

    seq = SequenceHelper.new("ui sequence")
    seq << @database.expects(:dirty?).returns(false)
    foo_group = stub('Foo group')
    seq << @console.expects(:menu).with(@menu_options).returns(:group => foo_group)

    seq << @database.expects(:dirty?).returns(false)
    seq << @console.expects(:menu).with(@menu_options.merge(:group => foo_group, :at_top => false)).returns(:quit)

    runner = Keyrack::Runner.new(["-d", @keyrack_dir])
  end

  test "selecting subgroup of group" do
    setup_config

    seq = SequenceHelper.new("ui sequence")
    seq << @database.expects(:dirty?).returns(false)
    foo_group = stub('Foo group')
    seq << @console.expects(:menu).with(@menu_options).returns(:group => foo_group)

    bar_group = stub('Bar group')
    seq << @database.expects(:dirty?).returns(false)
    seq << @console.expects(:menu).
      with(@menu_options.merge(:group => foo_group, :at_top => false)).
      returns(:group => bar_group)

    seq << @database.expects(:dirty?).returns(false)
    seq << @console.expects(:menu).
      with(@menu_options.merge(:group => bar_group, :at_top => false, :enable_up => true)).
      returns(:quit)

    runner = Keyrack::Runner.new(["-d", @keyrack_dir])
  end

  test "navigating to top" do
    setup_config

    seq = SequenceHelper.new("ui sequence")
    seq << @database.expects(:dirty?).returns(false)
    foo_group = stub('Foo group')
    seq << @console.expects(:menu).with(@menu_options).returns(:group => foo_group)

    seq << @database.expects(:dirty?).returns(false)
    seq << @console.expects(:menu).
      with(@menu_options.merge(:group => foo_group, :at_top => false)).
      returns(:top)

    seq << @database.expects(:dirty?).returns(false)
    seq << @console.expects(:menu).with(@menu_options).returns(:quit)

    runner = Keyrack::Runner.new(["-d", @keyrack_dir])
  end

  test "navigating up" do
    setup_config

    foo_group = stub('Foo group')
    bar_group = stub('Bar group')

    seq = SequenceHelper.new("ui sequence")
    seq << @database.expects(:dirty?).returns(false)
    seq << @console.expects(:menu).with(@menu_options).returns(:group => foo_group)

    seq << @database.expects(:dirty?).returns(false)
    seq << @console.expects(:menu).
      with(@menu_options.merge(:group => foo_group, :at_top => false)).
      returns(:group => bar_group)

    seq << @database.expects(:dirty?).returns(false)
    seq << @console.expects(:menu).
      with(@menu_options.merge(:group => bar_group, :at_top => false, :enable_up => true)).
      returns(:up)

    seq << @database.expects(:dirty?).returns(false)
    seq << @console.expects(:menu).
      with(@menu_options.merge(:group => foo_group, :at_top => false)).
      returns(:quit)

    runner = Keyrack::Runner.new(["-d", @keyrack_dir])
  end
end
