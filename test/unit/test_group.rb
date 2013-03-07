require 'helper'

class TestGroup < Test::Unit::TestCase
  def new_group(*args)
    Keyrack::Group.new(*args)
  end

  def new_site(*args)
    Keyrack::Site.new(*args)
  end

  test "initialize" do
    group = new_group("Starships")
    assert_equal "Starships", group.name
    assert_equal([], group.sites)
    assert_equal({}, group.groups)
  end

  test "initializing with no arguments makes read-only (until loaded)" do
    group = Keyrack::Group.new
    assert_raises(RuntimeError) { group.add_site(new_site('Foo')) }
    assert_raises(RuntimeError) { group.remove_site('Foo') }
    assert_raises(RuntimeError) { group.add_group(new_group('Foo')) }
    assert_raises(RuntimeError) { group.remove_group('Foo') }
  end

  test "add_site" do
    group = new_group("Starships")
    site = new_site("Enterprise", "picard", "livingston")
    group.add_site(site)
    assert_equal([site], group.sites)
  end

  test "add_site with same name" do
    group = new_group("Starships")
    site_1 = new_site("Enterprise", "picard", "livingston")
    group.add_site(site_1)
    site_2 = new_site("Enterprise", "riker", "trombone")
    group.add_site(site_2)
    assert_equal([site_1, site_2], group.sites)
  end

  test "adding already existing site raises error" do
    group = new_group("Starships")
    site = new_site("Enterprise", "picard", "livingston")
    group.add_site(site)
    assert_raises(Keyrack::GroupError) do
      group.add_site(site)
    end
  end

  test "adding invalid site raises error" do
    group = new_group("Starships")
    assert_raises(Keyrack::GroupError) do
      group.add_site("Pegasus")
    end
  end

  test "remove_site" do
    group = new_group("Starships")
    site = new_site("Enterprise", "picard", "livingston")
    group.add_site(site)
    group.remove_site(site)
    assert_equal([], group.sites)
  end

  test "removing non-existant site raises error" do
    group = new_group("Starships")
    site = new_site("Enterprise", "picard", "livingston")
    assert_raises(Keyrack::GroupError) do
      group.remove_site(site)
    end
  end

  test "add_group" do
    group = new_group("Starships")
    subgroup = new_group("Klingon")
    group.add_group(subgroup)

    expected = {"Klingon" => {'name' => "Klingon", 'sites' => [], 'groups' => {}}}
    assert_equal(expected, group.groups)
  end

  test "adding already existing group raises error" do
    group = new_group("Starships")
    subgroup = new_group("Klingon")
    group.add_group(subgroup)
    assert_raises(Keyrack::GroupError) do
      group.add_group(subgroup)
    end
  end

  test "adding invalid group raises error" do
    group = new_group("Starships")
    assert_raises(Keyrack::GroupError) do
      group.add_group("Klingon")
    end
  end

  test "remove_group" do
    group = new_group("Starships")
    subgroup = new_group("Klingon")
    group.add_group(subgroup)
    group.remove_group("Klingon")
    assert_equal({}, group.groups)
  end

  test "removing non-existant group raises error" do
    group = new_group("Starships")
    assert_raises(Keyrack::GroupError) do
      group.remove_group("Klingon")
    end
  end

  test "load group from hash" do
    hash = {
      'name' => "Starships",
      'sites' => [
        {
          'name' => 'Enterprise',
          'username' => 'picard',
          'password' => 'livingston'
        }
      ],
      'groups' => {
        "Klingon" => {
          'name' => "Klingon",
          'sites' => [
            {
              'name' => "Bortas",
              'username' => "gowron",
              'password' => "bat'leth"
            }
          ],
          'groups' => {}
        }
      }
    }
    group = new_group(hash)
    assert_equal "Starships", group.name
    assert_equal hash['sites'], group.sites
    assert_equal hash['groups'], group.groups

    group = Keyrack::Group.new
    group.load(hash)
    assert_equal "Starships", group.name
    assert_equal hash['sites'], group.sites
    assert_equal hash['groups'], group.groups
  end

  test "loading group from hash with missing name" do
    hash = {
      'sites' => [],
      'groups' => {}
    }
    assert_raises(ArgumentError) do
      group = new_group(hash)
    end
  end

  test "loading group from hash with non-string name" do
    hash = {
      'name' => [123],
      'sites' => [],
      'groups' => {}
    }
    assert_raises(ArgumentError) do
      group = new_group(hash)
    end
  end

  test "loading group with missing sites" do
    hash = {
      'name' => "Starships",
      'groups' => {}
    }
    assert_raises(ArgumentError) do
      group = new_group(hash)
    end
  end

  test "loading group with non-array sites" do
    hash = {
      'name' => "Starships",
      'sites' => "foo",
      'groups' => {}
    }
    assert_raises(ArgumentError) do
      group = new_group(hash)
    end
  end

  test "loading group with non-hash site" do
    hash = {
      'name' => "Starships",
      'sites' => [
        "foo"
      ],
      'groups' => {}
    }
    assert_raises(ArgumentError) do
      group = new_group(hash)
    end
  end

  test "loading group with invalid site" do
    hash = {
      'name' => "Starships",
      'sites' => [
        {"foo" => "bar"}
      ],
      'groups' => {}
    }
    assert_raises(ArgumentError) do
      group = new_group(hash)
    end
  end

  test "loading group with missing groups" do
    hash = {
      'name' => "Starships",
      'sites' => []
    }
    assert_raises(ArgumentError) do
      group = new_group(hash)
    end
  end

  test "loading group with non-hash groups" do
    hash = {
      'name' => "Starships",
      'sites' => [],
      'groups' => "foo"
    }
    assert_raises(ArgumentError) do
      group = new_group(hash)
    end
  end

  test "loading group with non-string group name" do
    hash = {
      'name' => "Starships",
      'sites' => [],
      'groups' => {
        [123] => {
          'name' => "Klingon",
          'sites' => [],
          'groups' => {}
        }
      },
    }
    assert_raises(ArgumentError) do
      group = new_group(hash)
    end
  end

  test "loading group with non-hash group value" do
    hash = {
      'name' => "Starships",
      'sites' => [],
      'groups' => {
        "foo" => "bar"
      }
    }
    assert_raises(ArgumentError) do
      group = new_group(hash)
    end
  end

  test "loading group with invalid sub-group" do
    hash = {
      'name' => "Starships",
      'sites' => [],
      'groups' => {
        "foo" => {"foo" => "bar"}
      }
    }
    assert_raises(ArgumentError) do
      group = new_group(hash)
    end
  end

  test "loading group with mismatched group names" do
    hash = {
      'name' => "Starships",
      'sites' => [],
      'groups' => {
        "Foo" => {
          'name' => "Klingon",
          'sites' => [],
          'groups' => {}
        }
      }
    }
    assert_raises(ArgumentError) do
      group = new_group(hash)
    end
  end

  test "site getter" do
    group = new_group("Starships")
    site = new_site("Enterprise", "picard", "livingston")
    group.add_site(site)
    assert_same site, group.site(0)
  end

  test "group getter" do
    group = new_group("Starships")
    subgroup = new_group("Klingon")
    group.add_group(subgroup)
    assert_same subgroup, group.group("Klingon")
  end

  test "group_names" do
    group = new_group("Starships")
    subgroup = new_group("Klingon")
    group.add_group(subgroup)
    assert_equal ["Klingon"], group.group_names
  end

  test "after_site_added callback" do
    group = new_group("Starships")
    site = new_site("Enterprise", "picard", "livingston")

    called = false
    group.after_site_added do |affected_group, added_site|
      called = true
      assert_same group, affected_group
      assert_same site, added_site
    end
    group.add_site(site)
    assert called
  end

  test "after_username_changed callback" do
    group = new_group("Starships")
    site = new_site("Enterprise", "picard", "livingston")
    group.add_site(site)

    called = false
    group.after_username_changed do |affected_group, affected_site|
      called = true
      assert_same group, affected_group
      assert_same site, affected_site
      assert_equal "jean_luc", affected_site.username
    end
    site.username = "jean_luc"
    assert called
  end

  test "after_username_changed callback for hash-loaded group" do
    group = new_group({
      'name' => "Starships",
      'sites' => [
        {
          'name' => 'Enterprise',
          'username' => 'picard',
          'password' => 'livingston'
        }
      ],
      'groups' => {}
    })
    site = group.site(0)

    called = false
    group.after_username_changed do |affected_group, affected_site|
      called = true
      assert_same group, affected_group
      assert_same site, affected_site
      assert_equal "jean_luc", affected_site.username
    end
    site.username = "jean_luc"
    assert called
  end

  test "after_password_changed callback" do
    group = new_group("Starships")
    site = new_site("Enterprise", "picard", "livingston")
    group.add_site(site)

    called = false
    group.after_password_changed do |affected_group, affected_site|
      called = true
      assert_same group, affected_group
      assert_same site, affected_site
      assert_equal "crusher", affected_site.password
    end
    site.password = "crusher"
    assert called
  end

  test "after_password_changed callback for hash-loaded group" do
    group = new_group({
      'name' => "Starships",
      'sites' => [
        {
          'name' => 'Enterprise',
          'username' => 'picard',
          'password' => 'livingston'
        }
      ],
      'groups' => {}
    })
    site = group.site(0)

    called = false
    group.after_password_changed do |affected_group, affected_site|
      called = true
      assert_same group, affected_group
      assert_same site, affected_site
      assert_equal "crusher", affected_site.password
    end
    site.password = "crusher"
    assert called
  end

  test "after_site_removed callback" do
    group = new_group("Starships")
    site = new_site("Enterprise", "picard", "livingston")
    group.add_site(site)

    called = false
    group.after_site_removed do |affected_group, removed_site|
      called = true
      assert_same group, affected_group
      assert_same site, removed_site
    end
    group.remove_site(site)
    assert called
  end

  test "after_group_added callback" do
    group = new_group("Starships")
    subgroup = new_group("Klingon")

    called = false
    group.after_group_added do |affected_group, added_group|
      called = true
      assert_same group, affected_group
      assert_same subgroup, added_group
    end
    group.add_group(subgroup)
    assert called
  end

  test "after_group_removed callback" do
    group = new_group("Starships")
    subgroup = new_group("Klingon")
    group.add_group(subgroup)

    called = false
    group.after_group_removed do |affected_group, removed_group|
      called = true
      assert_same group, affected_group
      assert_same subgroup, removed_group
    end
    group.remove_group("Klingon")
    assert called
  end

  test "to_yaml" do
    group = new_group("Starships")
    site = new_site("Enterprise", "picard", "livingston")
    group.add_site(site)
    subgroup = new_group("Klingon")
    subsite = new_site("Bortas", "gowron", "bat'leth")
    subgroup.add_site(subsite)
    group.add_group(subgroup)

    expected = {
      'name' => "Starships",
      'sites' => [
        {
          'name' => "Enterprise",
          'username' => 'picard',
          'password' => 'livingston'
        }
      ],
      'groups' => {
        "Klingon" => {
          'name' => "Klingon",
          'sites' => [
            {
              'name' => "Bortas",
              'username' => 'gowron',
              'password' => "bat'leth"
            }
          ],
          'groups' => {}
        }
      }
    }.to_yaml
    assert_equal expected, group.to_yaml
  end
end
