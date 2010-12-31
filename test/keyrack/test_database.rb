require 'helper'

module Keyrack
  class TestDatabase < Test::Unit::TestCase
    def setup
      @key = "abcdefgh" * 32
      @iv = @key.reverse

      @path = get_tmpname
      @store = Store['filesystem'].new('path' => @path)

      @database = Keyrack::Database.new(@key, @iv, @store)
      @database.add('Twitter', 'username', 'password')
      @database.save
    end

    def test_encrypts_database
      encrypted_data = File.read(@path)
      cipher = OpenSSL::Cipher::Cipher.new("AES-128-CBC")
      cipher.decrypt; cipher.key = @key; cipher.iv = @iv
      marshalled_data = cipher.update(encrypted_data) + cipher.final
      data = Marshal.load(marshalled_data)
      assert_equal({'Twitter'=>{:username=>'username',:password=>'password'}}, data)
    end

    def test_reading_existing_database
      database = Keyrack::Database.new(@key, @iv, @store)
      expected = {:username => 'username', :password => 'password'}
      assert_equal(expected, database.get('Twitter'))
    end

    def test_sites
      assert_equal(%w{Twitter}, @database.sites)
    end

    def test_dirty
      assert !@database.dirty?
      @database.add('Foo', 'bar', 'baz')
      assert @database.dirty?
    end

    def test_large_number_of_entries
      site = "abcdefg"; user = "1234567"; pass = "zyxwvut" * 2
      500.times do |i|
        @database.add(site, user, pass)
        site.next!; user.next!; pass.next!
      end
      @database.save
      assert_equal 501, @database.sites.length
    end
  end
end
