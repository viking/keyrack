require 'helper'

class TestDatabase < Test::Unit::TestCase
  def setup
    @path = get_tmpname
    @store = Keyrack::Store['filesystem'].new('path' => @path)

    @encrypt_options = { :maxmem => 0, :maxmemfrac => 0.05, :maxtime => 0.1 }
    @decrypt_options = { :maxmem => 0, :maxmemfrac => 0.10, :maxtime => 1.0 }
    @key = "secret"
    @database = Keyrack::Database.new(@key, @store, @encrypt_options, @decrypt_options)
    twitter = Keyrack::Site.new('Twitter')
    twitter.add_login('dude', 'p4ssword')
    @database.top_group.add_site(twitter)
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
          'sites' => {
            'Twitter' => {
              'name' => 'Twitter',
              'logins' => {'dude' => 'p4ssword'}
            }
          },
          'groups' => {}
        }
      },
      'version' => Keyrack::Database::VERSION
    }
    assert_equal(expected, data)
  end

  test "database is dirty after adding site to top group" do
    assert !@database.dirty?
    site = Keyrack::Site.new('Foo')
    @database.top_group.add_site(site)
    assert @database.dirty?
  end

  test "database is dirty after removing site from top group" do
    assert !@database.dirty?
    @database.top_group.remove_site('Twitter')
    assert @database.dirty?
  end

  test "database is dirty after adding login to site" do
    assert !@database.dirty?
    twitter = @database.top_group.site('Twitter')
    twitter.add_login('foo', 'bar')
    assert @database.dirty?
  end

  test "database is dirty after removing login from site" do
    assert !@database.dirty?
    twitter = @database.top_group.site('Twitter')
    twitter.remove_login('dude')
    assert @database.dirty?
  end

  test "database is dirty after changing username" do
    assert !@database.dirty?
    twitter = @database.top_group.site('Twitter')
    twitter.change_username('dude', 'bro')
    assert @database.dirty?
  end

  test "database is dirty after changing password" do
    assert !@database.dirty?
    twitter = @database.top_group.site('Twitter')
    twitter.change_password('dude', 'secret')
    assert @database.dirty?
  end

  test "database is dirty after adding subgroup" do
    assert !@database.dirty?
    group = Keyrack::Group.new('Foo')
    @database.top_group.add_group(group)
    assert @database.dirty?
  end

  test "database is dirty after removing subgroup" do
    group = Keyrack::Group.new('Foo')
    @database.top_group.add_group(group)
    assert @database.save(@key)

    assert !@database.dirty?
    @database.top_group.remove_group('Foo')
    assert @database.dirty?
  end

  test "database is dirty after adding site to subgroup" do
    assert !@database.dirty?
    group = Keyrack::Group.new('Foo')
    @database.top_group.add_group(group)
    assert @database.save(@key)

    assert !@database.dirty?
    site = Keyrack::Site.new('Bar')
    group.add_site(site)
    assert @database.dirty?
  end

  test "database is dirty after removing site from subgroup" do
    assert !@database.dirty?
    group = Keyrack::Group.new('Foo')
    @database.top_group.add_group(group)
    assert @database.save(@key)

    assert !@database.dirty?
    site = Keyrack::Site.new('Bar')
    group.add_site(site)
    assert @database.save(@key)

    assert !@database.dirty?
    group.remove_site('Bar')
    assert @database.dirty?
  end

  test "database is dirty after adding group to subgroup" do
    assert !@database.dirty?
    group = Keyrack::Group.new('Foo')
    @database.top_group.add_group(group)
    assert @database.save(@key)

    assert !@database.dirty?
    subgroup = Keyrack::Group.new('Bar')
    group.add_group(subgroup)
    assert @database.dirty?
  end

  test "large number of entries" do
    site_name = "abcdefg"; username = "1234567"; password = "zyxwvut" * 2
    500.times do |i|
      site = Keyrack::Site.new(site_name)
      site.add_login(username, password)
      @database.top_group.add_site(site)
      site_name.next!; username.next!; password.next!
    end
    assert @database.save(@key)
    assert_equal 501, @database.top_group.sites.length
  end

  test "saving requires same password as creation" do
    site = Keyrack::Site.new("Foo")
    site.add_login("bar", "baz")
    @database.top_group.add_site(site)

    assert !@database.save("bogus")
  end

  test "changing database password successfully" do
    assert @database.change_password(@key, "new-secret")

    site = Keyrack::Site.new("Foo")
    site.add_login("bar", "baz")
    @database.top_group.add_site(site)

    assert @database.save("new-secret")
  end

  test "attempting to change database password with wrong existing password" do
    assert !@database.change_password("bogus", "new-secret")

    site = Keyrack::Site.new("Foo")
    site.add_login("bar", "baz")
    @database.top_group.add_site(site)

    assert !@database.save("new-secret")
  end
end
