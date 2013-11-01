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

  test "change name" do
    group = new_group("Starships")
    assert_equal "Starships", group.name
    group.name = "Galaxy class starships"
    assert_equal "Galaxy class starships", group.name
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

    assert_equal 1, group.groups.length
    group = group.group('Klingon')
    assert_equal 'Klingon', group.name
    assert_equal [], group.sites
    assert_equal({}, group.groups)
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
    values = [new_group(hash), Keyrack::Group.new]
    values[1].load(hash)
    values.each do |group|
      assert_equal "Starships", group.name
      assert_equal 1, group.sites.length
      assert_kind_of Keyrack::Site, group.site(0)
      assert_equal 1, group.groups.length
      assert_kind_of Keyrack::Group, group.group('Klingon')
    end
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

  test "loading group from hash does not call hooks" do
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
    group = Keyrack::Group.new
    called = false
    group.after_event { |_| called = true }
    group.load(hash)
    assert !called
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

  test "name changed callback" do
    group = new_group("Starships")

    called = false
    group.after_event do |event|
      called = true
      assert_same group, event.owner
      assert_equal 'change', event.name
      assert_equal 'name', event.attribute_name
      assert_equal 'Starships', event.previous_value
      assert_equal 'Galaxy class starships', event.new_value
    end
    group.name = 'Galaxy class starships'
    assert called
  end

  test "name changed callback for subgroup" do
    group = new_group("Starships")
    subgroup = new_group("Galaxy class")
    group.add_group(subgroup)

    called = false
    group.after_event do |event|
      called = true
      assert_same group, event.owner
      assert_equal 'change', event.name
      assert_not_nil event.parent
      assert_same subgroup, event.parent.owner
    end
    subgroup.name = "Excelsior class"
    assert called
  end

  test "group updates subgroup names after subgroup's name changes" do
    group = new_group("Starships")
    subgroup = new_group("Galaxy class")
    group.add_group(subgroup)
    assert_equal({'Galaxy class' => subgroup}, group.groups)
    subgroup.name = 'Soyuz class'
    assert_equal({'Soyuz class' => subgroup}, group.groups)
  end

  test "site added callback" do
    group = new_group("Starships")
    site = new_site("Enterprise", "picard", "livingston")

    called = false
    group.after_event do |event|
      called = true
      assert_same group, event.owner
      assert_equal 'add', event.name
      assert_equal 'sites', event.collection_name
      assert_same site, event.object
    end
    group.add_site(site)
    assert called
  end

  test "site added callback for subgroup" do
    group = new_group("Starships")
    subgroup = new_group("Galaxy class")
    group.add_group(subgroup)
    site = new_site("Enterprise", "picard", "livingston")

    called = false
    group.after_event do |event|
      called = true
      assert_same group, event.owner
      assert_equal 'change', event.name
      assert_not_nil event.parent
      assert_same subgroup, event.parent.owner
    end
    subgroup.add_site(site)
    assert called
  end

  test "site username changed callback" do
    group = new_group("Starships")
    site = new_site("Enterprise", "picard", "livingston")
    group.add_site(site)

    called = false
    group.after_event do |event|
      called = true
      assert_same group, event.owner
      assert_equal 'change', event.name
      assert_not_nil event.parent
      assert_same site, event.parent.owner
    end
    site.username = "jean_luc"
    assert called
  end

  test "site username changed callback for hash-loaded group" do
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
    group.after_event do |event|
      called = true
      assert_same group, event.owner
      assert_equal 'change', event.name
      assert_not_nil event.parent
      assert_same site, event.parent.owner
    end
    site.username = "jean_luc"
    assert called
  end

  test "site username changed callback for subgroup" do
    group = new_group("Starships")
    subgroup = new_group("Galaxy class")
    group.add_group(subgroup)
    site = new_site("Enterprise", "picard", "livingston")
    subgroup.add_site(site)

    called = false
    group.after_event do |event|
      called = true
      assert_same group, event.owner
      assert_equal 'change', event.name
      assert_not_nil event.parent
      assert_same subgroup, event.parent.owner
      assert_not_nil event.parent.parent
      assert_same site, event.parent.parent.owner
    end
    site.username = "jean_luc"
    assert called
  end

  test "site password changed callback" do
    group = new_group("Starships")
    site = new_site("Enterprise", "picard", "livingston")
    group.add_site(site)

    called = false
    group.after_event do |event|
      called = true
      assert_same group, event.owner
      assert_equal 'change', event.name
      assert_not_nil event.parent
      assert_same site, event.parent.owner
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
    group.after_event do |event|
      called = true
      assert_same group, event.owner
      assert_equal 'change', event.name
      assert_not_nil event.parent
      assert_same site, event.parent.owner
    end
    site.password = "crusher"
    assert called
  end

  test "site password changed callback for subgroup" do
    group = new_group("Starships")
    subgroup = new_group("Galaxy class")
    group.add_group(subgroup)
    site = new_site("Enterprise", "picard", "livingston")
    subgroup.add_site(site)

    called = false
    group.after_event do |event|
      called = true
      assert_same group, event.owner
      assert_equal 'change', event.name
      assert_not_nil event.parent
      assert_same subgroup, event.parent.owner
      assert_not_nil event.parent.parent
      assert_same site, event.parent.parent.owner
    end
    site.password = "crusher"
    assert called
  end

  test "site removed callback" do
    group = new_group("Starships")
    site = new_site("Enterprise", "picard", "livingston")
    group.add_site(site)

    called = false
    group.after_event do |event|
      called = true
      assert_same group, event.owner
      assert_equal 'remove', event.name
      assert_equal 'sites', event.collection_name
      assert_same site, event.object
    end
    group.remove_site(site)
    assert called
  end

  test "site removed callback for subgroup" do
    group = new_group("Starships")
    subgroup = new_group("Galaxy class")
    group.add_group(subgroup)
    site = new_site("Enterprise", "picard", "livingston")
    subgroup.add_site(site)

    called = false
    group.after_event do |event|
      called = true
      assert_same group, event.owner
      assert_equal 'change', event.name
      assert_not_nil event.parent
      assert_same subgroup, event.parent.owner
    end
    subgroup.remove_site(site)
    assert called
  end

  test "group added callback" do
    group = new_group("Starships")
    subgroup = new_group("Klingon")

    called = false
    group.after_event do |event|
      called = true
      assert_same group, event.owner
      assert_equal 'add', event.name
      assert_equal 'groups', event.collection_name
      assert_same subgroup, event.object
    end
    group.add_group(subgroup)
    assert called
  end

  test "group added callback for subgroup" do
    group = new_group("Starships")
    subgroup = new_group("Galaxy class")
    group.add_group(subgroup)
    subsubgroup = new_group("Flagships")

    called = false
    group.after_event do |event|
      called = true
      assert_same group, event.owner
      assert_equal 'change', event.name
      assert_not_nil event.parent
      assert_same subgroup, event.parent.owner
    end
    subgroup.add_group(subsubgroup)
    assert called
  end

  test "group removed callback" do
    group = new_group("Starships")
    subgroup = new_group("Klingon")
    group.add_group(subgroup)

    called = false
    group.after_event do |event|
      called = true
      assert_same group, event.owner
      assert_equal 'remove', event.name
      assert_equal 'groups', event.collection_name
      assert_same subgroup, event.object
    end
    group.remove_group("Klingon")
    assert called
  end

  test "group removed callback for subgroup" do
    group = new_group("Starships")
    subgroup = new_group("Galaxy class")
    group.add_group(subgroup)
    subsubgroup = new_group("Flagships")
    subgroup.add_group(subsubgroup)

    called = false
    group.after_event do |event|
      called = true
      assert_same group, event.owner
      assert_equal 'change', event.name
      assert_not_nil event.parent
      assert_same subgroup, event.parent.owner
    end
    subgroup.remove_group("Flagships")
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

  test "to_h" do
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
    }
    assert_equal expected, group.to_h
  end
end
