require 'helper'

class TestDatabase < Test::Unit::TestCase
  def setup
    @key = "abcdefgh" * 32
    @iv = @key.reverse

    @path = get_tmpname
    @store = Keyrack::Store['filesystem'].new('path' => @path)

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
    assert_equal(expected, database.get('Twitter', 'username'))
  end

  def test_sites
    @database.add('Blargh', 'dudeguy', 'secret', :group => "Junk")
    assert_equal(%w{Twitter}, @database.sites)
    assert_equal(%w{Blargh}, @database.sites(:group => "Junk"))
    assert_equal([], @database.sites(:group => "New group"))
  end

  def test_groups
    assert_equal [], @database.groups
    @database.add('Blargh', 'dudeguy', 'secret', :group => "Junk")
    assert_equal %w{Junk}, @database.groups
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

  def test_add_with_top_level_group
    @database.add('Twitter', 'dudeguy', 'secret', :group => "Social")
    expected = {:username => 'dudeguy', :password => 'secret'}
    assert_equal expected, @database.get('Twitter', 'dudeguy', :group => "Social")
  end

  def test_delete
    @database.delete('Twitter', 'username')
    assert_equal [], @database.sites
    assert @database.dirty?
  end

  def test_delete_non_existant_entry
    @database.delete('Twitter', 'foobar')
    assert_equal ['Twitter'], @database.sites
    assert !@database.dirty?
  end

  def test_delete_group_entry
    @database.add('Facebook', 'dudeguy', 'secret', :group => "Social")
    @database.delete('Facebook', 'dudeguy', :group => 'Social')
    assert_equal [], @database.sites(:group => 'Social')
    assert_equal ['Twitter'], @database.sites
  end

  def test_multiple_entries_with_the_same_site
    @database.add('Facebook', 'dudeguy', 'secret')
    @database.add('Facebook', 'foobar', 'secret')

    expected_1 = {:username => 'dudeguy', :password => 'secret'}
    assert_equal expected_1, @database.get('Facebook', 'dudeguy')
    expected_2 = {:username => 'foobar', :password => 'secret'}
    assert_equal expected_2, @database.get('Facebook', 'foobar')
    assert_equal [expected_1, expected_2], @database.get('Facebook')
    assert_equal ['Facebook', 'Twitter'], @database.sites
  end

  def test_get_missing_entry_by_site_and_username
    @database.add('Facebook', 'dudeguy', 'secret')
    assert_nil @database.get('Facebook', 'foobar')
  end

  def test_deleting_one_of_two_entries_with_the_same_site
    @database.add('Facebook', 'dudeguy', 'secret')
    @database.add('Facebook', 'foobar', 'secret')
    @database.delete('Facebook', 'dudeguy')
    assert_nil @database.get('Facebook', 'dudeguy')
    assert_equal({:username => 'foobar', :password => 'secret'}, @database.get('Facebook', 'foobar'))
  end
end
