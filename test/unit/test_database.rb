require 'helper'

class TestDatabase < Test::Unit::TestCase
  class TestReload < self
    def setup
      super
      @database = Keyrack::Database.new(@key, @store, @encrypt_options, @decrypt_options)
    end
  end

  def self.database_test(test_description, reload, &block)
    if reload
      TestReload.class_eval do
        test(test_description, &block)
      end
    else
      test(test_description, &block)
    end
  end

  def setup
    @path = get_tmpname
    @store = Keyrack::Store['filesystem'].new('path' => @path)

    @encrypt_options = { :maxmem => 0, :maxmemfrac => 0.05, :maxtime => 0.1 }
    @decrypt_options = { :maxmem => 0, :maxmemfrac => 0.10, :maxtime => 1.0 }
    @key = "secret"
    @database = Keyrack::Database.new(@key, @store, @encrypt_options, @decrypt_options)
    @twitter = Keyrack::Site.new('Twitter', 'dude', 'p4ssword')
    @database.top_group.add_site(@twitter)
    assert @database.save(@key)
  end

  def decrypt(data, key = @key, options = @decrypt_options)
    Scrypty.decrypt(data, key, *options.values_at(:maxmem, :maxmemfrac, :maxtime))
  end

  test "encrypting database" do
    encrypted_data = File.read(@path)
    yaml = decrypt(encrypted_data, @key)
    data = YAML.load(yaml)
    expected = {
      'groups' => {
        'top' => {
          'name' => 'top',
          'sites' => [
            {
              'name' => 'Twitter',
              'username' => 'dude',
              'password' => 'p4ssword'
            }
          ],
          'groups' => {}
        }
      },
      'version' => Keyrack::Database::VERSION
    }
    assert_equal(expected, data)
  end

  test "auto-migrating database from version 3" do
    store = Keyrack::Store['filesystem'].new('path' => fixture_path('database-3.dat'))
    assert_nothing_raised do
      database = Keyrack::Database.new('foobar', store)
    end
  end

  [true, false].each do |reload|
    database_test "database is dirty after adding site to top group", reload do
      assert !@database.dirty?
      site = Keyrack::Site.new('Foo', 'foo', 'bar')
      @database.top_group.add_site(site)
      assert @database.dirty?
    end

    database_test "database is dirty after removing site from top group", reload do
      assert !@database.dirty?
      @database.top_group.remove_site(@twitter)
      assert @database.dirty?
    end

    database_test "database is dirty after changing username", reload do
      assert !@database.dirty?
      twitter = @database.top_group.site(0)
      twitter.username = 'bro'
      assert @database.dirty?
    end

    database_test "database is dirty after changing password", reload do
      assert !@database.dirty?
      twitter = @database.top_group.site(0)
      twitter.password = 'secret'
      assert @database.dirty?
    end

    database_test "database is dirty after adding subgroup", reload do
      assert !@database.dirty?
      group = Keyrack::Group.new('Foo')
      @database.top_group.add_group(group)
      assert @database.dirty?
    end

    database_test "database is dirty after removing subgroup", reload do
      group = Keyrack::Group.new('Foo')
      @database.top_group.add_group(group)
      assert @database.save(@key)

      assert !@database.dirty?
      @database.top_group.remove_group('Foo')
      assert @database.dirty?
    end

    database_test "database is dirty after adding site to subgroup", reload do
      assert !@database.dirty?
      group = Keyrack::Group.new('Foo')
      @database.top_group.add_group(group)
      assert @database.save(@key)

      assert !@database.dirty?
      site = Keyrack::Site.new('Bar', 'bar', 'baz')
      group.add_site(site)
      assert @database.dirty?
    end

    database_test "database is dirty after removing site from subgroup", reload do
      assert !@database.dirty?
      group = Keyrack::Group.new('Foo')
      @database.top_group.add_group(group)
      assert @database.save(@key)

      assert !@database.dirty?
      site = Keyrack::Site.new('Bar', 'bar', 'baz')
      group.add_site(site)
      assert @database.save(@key)

      assert !@database.dirty?
      group.remove_site(site)
      assert @database.dirty?
    end

    database_test "database is dirty after adding group to subgroup", reload do
      assert !@database.dirty?
      group = Keyrack::Group.new('Foo')
      @database.top_group.add_group(group)
      assert @database.save(@key)

      assert !@database.dirty?
      subgroup = Keyrack::Group.new('Bar')
      group.add_group(subgroup)
      assert @database.dirty?
    end

    database_test "large number of entries", reload do
      site_name = "abcdefg"; username = "1234567"; password = "zyxwvut" * 2
      500.times do |i|
        site = Keyrack::Site.new(site_name, username, password)
        @database.top_group.add_site(site)
        site_name = site_name.next
        username = username.next
        password = password.next
      end
      assert @database.save(@key)
      assert_equal 501, @database.top_group.sites.length
    end

    database_test "saving requires same password as creation", reload do
      site = Keyrack::Site.new("Foo", 'foo', 'bar')
      @database.top_group.add_site(site)

      assert !@database.save("bogus")
    end

    database_test "changing database password successfully", reload do
      assert @database.change_password(@key, "new-secret")

      site = Keyrack::Site.new("Foo", 'bar', 'baz')
      @database.top_group.add_site(site)

      assert @database.save("new-secret")
    end

    database_test "attempting to change database password with wrong existing password", reload do
      assert !@database.change_password("bogus", "new-secret")

      site = Keyrack::Site.new("Foo", 'foo', 'bar')
      @database.top_group.add_site(site)

      assert !@database.save("new-secret")
    end
  end
end
