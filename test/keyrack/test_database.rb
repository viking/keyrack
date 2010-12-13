require 'helper'

module Keyrack
  class TestDatabase < Test::Unit::TestCase
    def setup
      @path = get_tmpname
      @database = Keyrack::Database.new({
        'store' => { 'type' => 'filesystem', 'path' => @path },
        'key' => fixture_path('id_rsa'),
        'password' => 'secret'
      })
      @database.add('Twitter', 'username', 'password')
      @database.save
    end

    def test_encrypts_database
      key = OpenSSL::PKey::RSA.new(File.read(fixture_path('id_rsa')), 'secret')
      encrypted_data = File.read(@path)
      marshalled_data = key.private_decrypt(encrypted_data)
      data = Marshal.load(marshalled_data)
      assert_equal({'Twitter'=>{:username=>'username',:password=>'password'}}, data)
    end

    def test_reading_existing_database
      database = Keyrack::Database.new({
        'store' => { 'type' => 'filesystem', 'path' => @path },
        'key' => fixture_path('id_rsa'),
        'password' => 'secret'
      })
      expected = {:username => 'username', :password => 'password'}
      assert_equal(expected, database.get('Twitter'))
    end

    def test_sites
      assert_equal(%w{Twitter}, @database.sites)
    end
  end
end
