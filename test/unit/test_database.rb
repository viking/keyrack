require 'helper'

class TestDatabase < Test::Unit::TestCase
  def setup
    @path = get_tmpname
    @store = Keyrack::Store['filesystem'].new('path' => @path)

    @options = { :maxmem => 0, :maxmemfrac => 0.05, :maxtime => 0.1 }
    @key = "secret"
    @database = Keyrack::Database.new(@key, @store, @options)
    @database.add('Twitter', 'dude', 'p4ssword')
    @database.save(@key)
  end

  def decrypt(data, key = @key, options = @options)
    Scrypty.decrypt(data, key, *options.values_at(:maxmem, :maxmemfrac, :maxtime))
  end

  def test_encrypts_database
    encrypted_data = File.read(@path)
    marshalled_data = decrypt(encrypted_data)
    data = Marshal.load(marshalled_data)
    expected = {
      :data => {
        'Twitter' => {:username => 'dude', :password => 'p4ssword'}
      },
      :version => Keyrack::Database::VERSION
    }
    assert_equal(expected, data)
  end

  def test_reading_existing_database
    database = Keyrack::Database.new(@key, @store)
    expected = {:username => 'dude', :password => 'p4ssword'}
    assert_equal(expected, database.get('Twitter', 'dude'))
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
    @database.save(@key)
    assert_equal 501, @database.sites.length
  end

  def test_add_with_top_level_group
    @database.add('Twitter', 'dudeguy', 'secret', :group => "Social")
    expected = {:username => 'dudeguy', :password => 'secret'}
    assert_equal expected, @database.get('Twitter', 'dudeguy', :group => "Social")
  end

  def test_delete
    @database.delete('Twitter', 'dude')
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
