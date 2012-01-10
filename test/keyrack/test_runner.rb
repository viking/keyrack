require 'helper'

module Keyrack
  class TestRunner < Test::Unit::TestCase
    def setup
      @console = stub('console', {
        :get_password => 'secret',
        :database= => nil, :menu => :quit,
        :get_new_entry => {:site => "Foo", :username => "bar", :password => "baz"}
      })
      UI::Console.stubs(:new).returns(@console)
      @database = stub('database', { :add => nil })
      Database.stubs(:new).returns(@database)
    end

    def test_console
      store_path = 'foo/bar/hey/buddy'
      rsa_path = 'omg/rsa/path'
      aes_path = 'hey/its/some/aes/stuff'
      config = {
        'store' => { 'type' => 'filesystem', 'path' => store_path },
        'rsa' => rsa_path, 'aes' => aes_path
      }
      keyrack_dir = get_tmpname
      Dir.mkdir(keyrack_dir)
      File.open(File.join(keyrack_dir, "config"), 'w') { |f| f.print(config.to_yaml) }

      UI::Console.expects(:new).returns(@console)

      seq = sequence('ui sequence')
      @console.expects(:get_password).returns('secret').in_sequence(seq)
      rsa = mock("rsa key")
      Utils.expects(:open_rsa_key).with(File.expand_path(rsa_path, keyrack_dir), 'secret').returns(rsa).in_sequence(seq)
      aes = {'key' => '12345', 'iv' => '54321'}
      Utils.expects(:open_aes_data).with(File.expand_path(aes_path, keyrack_dir), rsa).returns(aes).in_sequence(seq)
      store = mock('filesystem store')
      Store::Filesystem.expects(:new).with('path' => store_path).returns(store).in_sequence(seq)
      Database.expects(:new).with('12345', '54321', store).returns(@database).in_sequence(seq)
      @console.expects(:database=).with(@database).in_sequence(seq)

      @console.expects(:menu).returns(:new).in_sequence(seq)
      @console.expects(:get_new_entry).returns({:site => "Foo", :username => "bar", :password => "baz"}).in_sequence(seq)
      @database.expects(:add).with("Foo", "bar", "baz", {})
      @console.expects(:menu).returns(nil).in_sequence(seq)
      @console.expects(:menu).returns(:save).in_sequence(seq)
      @database.expects(:save).in_sequence(seq)
      @console.expects(:menu).returns(:delete).in_sequence(seq)
      @console.expects(:delete_entry).with({}).in_sequence(seq)
      @console.expects(:menu).returns(:new_group).in_sequence(seq)
      @console.expects(:get_new_group).returns(:group => 'Blah').in_sequence(seq)
      @console.expects(:menu).with(:group => 'Blah').returns(:top).in_sequence(seq)
      @console.expects(:menu).returns(:group => 'Huge').in_sequence(seq)
      @console.expects(:menu).with(:group => 'Huge').returns(nil).in_sequence(seq)
      @console.expects(:menu).with(:group => 'Huge').returns(:new).in_sequence(seq)
      @console.expects(:get_new_entry).returns({:site => "Bar", :username => "bar", :password => "baz"}).in_sequence(seq)
      @database.expects(:add).with("Bar", "bar", "baz", :group => 'Huge')
      @console.expects(:menu).with(:group => "Huge").returns(:delete).in_sequence(seq)
      @console.expects(:delete_entry).with(:group => 'Huge').in_sequence(seq)
      @console.expects(:menu).with(:group => 'Huge').returns(:top).in_sequence(seq)
      @console.expects(:menu).returns(:quit).in_sequence(seq)

      runner = Runner.new(["-d", keyrack_dir])
    end

    def test_console_first_run
      keyrack_dir = get_tmpname
      seq = sequence('ui sequence')

      @console.expects(:display_first_time_notice).in_sequence(seq)

      # RSA generation
      rsa_path = 'id_rsa'
      @console.expects(:rsa_setup).returns('password' => 'secret', 'path' => rsa_path).in_sequence(seq)
      rsa = mock('rsa key')
      Utils.expects(:generate_rsa_key).with('secret').returns([rsa, 'private key']).in_sequence(seq)

      # AES generation
      Utils.expects(:generate_aes_key).twice.returns('foobar', 'barfoo').in_sequence(seq)
      dump = Marshal.dump('key' => 'foobar', 'iv' => 'barfoo')
      rsa.expects(:public_encrypt).with(dump).returns("encrypted dump")

      # Store setup
      @console.expects(:store_setup).returns('type' => 'filesystem', 'path' => 'database').in_sequence(seq)
      store = mock('filesystem store')
      Store::Filesystem.expects(:new).with('path' => File.join(keyrack_dir, 'database')).returns(store).in_sequence(seq)

      Database.expects(:new).with('foobar', 'barfoo', store).returns(@database).in_sequence(seq)
      @console.expects(:database=).with(@database).in_sequence(seq)
      @console.expects(:menu).returns(:quit).in_sequence(seq)

      runner = Runner.new(["-d", keyrack_dir])

      assert Dir.exist?(keyrack_dir)
      expected_rsa_file = File.expand_path(rsa_path, keyrack_dir)
      assert File.exist?(expected_rsa_file)
      assert_equal 'private key', File.read(expected_rsa_file)

      expected_aes_file = File.expand_path('aes', keyrack_dir)
      assert File.exist?(expected_aes_file)
      assert_equal 'encrypted dump', File.read(expected_aes_file)

      expected_config_file = File.expand_path('config', keyrack_dir)
      assert File.exist?(expected_config_file)
      expected_config = {
        'rsa' => expected_rsa_file, 'aes' => expected_aes_file,
        'store' => { 'type' => 'filesystem', 'path' => File.join(keyrack_dir, 'database') }
      }
      assert_equal expected_config, YAML.load_file(expected_config_file)
    end
  end
end
