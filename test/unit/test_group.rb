require 'helper'

class TestGroup < Test::Unit::TestCase
  def new_group(arg)
    Keyrack::Group.new(arg)
  end

  def new_site(arg)
    Keyrack::Site.new(arg)
  end

  test "initialize" do
    group = new_group("Starships")
    assert_equal "Starships", group.name
    assert_equal({}, group.sites)
    assert_equal({}, group.groups)
  end

  test "add_site" do
    group = new_group("Starships")
    site = new_site("Enterprise")
    group.add_site(site)
    assert_equal({"Enterprise" => site}, group.sites)
  end

  test "adding already existing site raises error" do
    group = new_group("Starships")
    site = new_site("Enterprise")
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
    site = new_site("Enterprise")
    group.add_site(site)
    group.remove_site("Enterprise")
    assert_equal({}, group.sites)
  end

  test "removing non-existant site raises error" do
    group = new_group("Starships")
    assert_raises(Keyrack::GroupError) do
      group.remove_site("Enterprise")
    end
  end

  test "add_group" do
    group = new_group("Starships")
    subgroup = new_group("Klingon")
    group.add_group(subgroup)

    expected = {"Klingon" => {'name' => "Klingon", 'sites' => {}, 'groups' => {}}}
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
      'sites' => {
        "Enterprise" => {
          'name' => "Enterprise",
          'logins' => {"picard" => "livingston"}
        }
      },
      'groups' => {
        "Klingon" => {
          'name' => "Klingon",
          'sites' => {
            "Bortas" => {
              'name' => "Bortas",
              'logins' => {"gowron" => "bat'leth"}
            }
          },
          'groups' => {}
        }
      }
    }
    group = new_group(hash)
    assert_equal "Starships", group.name
    assert_equal hash['sites'], group.sites
    assert_equal hash['groups'], group.groups
  end

  test "loading group from hash with missing name" do
    hash = {
      'sites' => {},
      'groups' => {}
    }
    assert_raises(ArgumentError) do
      group = new_group(hash)
    end
  end

  test "loading group from hash with non-string name" do
    hash = {
      'name' => [123],
      'sites' => {},
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

  test "loading group with non-hash sites" do
    hash = {
      'name' => "Starships",
      'sites' => "foo",
      'groups' => {}
    }
    assert_raises(ArgumentError) do
      group = new_group(hash)
    end
  end

  test "loading group with non-string site name" do
    hash = {
      'name' => "Starships",
      'sites' => {
        [123] => {
          'name' => "Enterprise",
          'logins' => {"picard" => "livingston"}
        }
      },
      'groups' => {}
    }
    assert_raises(ArgumentError) do
      group = new_group(hash)
    end
  end

  test "loading group with non-hash site value" do
    hash = {
      'name' => "Starships",
      'sites' => {
        "foo" => "foo"
      },
      'groups' => {}
    }
    assert_raises(ArgumentError) do
      group = new_group(hash)
    end
  end

  test "loading group with invalid site" do
    hash = {
      'name' => "Starships",
      'sites' => {
        "foo" => {"foo" => "bar"}
      },
      'groups' => {}
    }
    assert_raises(ArgumentError) do
      group = new_group(hash)
    end
  end

  test "loading group with mismatched site names" do
    hash = {
      'name' => "Starships",
      'sites' => {
        "Foo" => {
          'name' => "Enterprise",
          'logins' => {"picard" => "livingston"}
        }
      },
      'groups' => {}
    }
    assert_raises(ArgumentError) do
      group = new_group(hash)
    end
  end

  test "loading group with missing groups" do
    hash = {
      'name' => "Starships",
      'sites' => {}
    }
    assert_raises(ArgumentError) do
      group = new_group(hash)
    end
  end

  test "loading group with non-hash groups" do
    hash = {
      'name' => "Starships",
      'sites' => {},
      'groups' => "foo"
    }
    assert_raises(ArgumentError) do
      group = new_group(hash)
    end
  end

  test "loading group with non-string group name" do
    hash = {
      'name' => "Starships",
      'sites' => {},
      'groups' => {
        [123] => {
          'name' => "Klingon",
          'sites' => {},
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
      'sites' => {},
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
      'sites' => {},
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
      'sites' => {},
      'groups' => {
        "Foo" => {
          'name' => "Klingon",
          'sites' => {},
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
    site = new_site("Enterprise")
    group.add_site(site)
    assert_same site, group.site("Enterprise")
  end

  test "group getter" do
    group = new_group("Starships")
    subgroup = new_group("Klingon")
    group.add_group(subgroup)
    assert_same subgroup, group.group("Klingon")
  end

  test "site_names" do
    group = new_group("Starships")
    site = new_site("Enterprise")
    group.add_site(site)
    assert_equal ["Enterprise"], group.site_names
  end

  test "group_names" do
    group = new_group("Starships")
    subgroup = new_group("Klingon")
    group.add_group(subgroup)
    assert_equal ["Klingon"], group.group_names
  end

  test "after_site_added callback" do
    group = new_group("Starships")
    site = new_site("Enterprise")

    called = false
    group.after_site_added do |affected_group, added_site|
      called = true
      assert_same group, affected_group
      assert_same site, added_site
    end
    group.add_site(site)
    assert called
  end

  test "after_login_added callback" do
    group = new_group("Starships")
    site = new_site("Enterprise")
    group.add_site(site)

    called = false
    group.after_login_added do |affected_group, changed_site, username, password|
      called = true
      assert_same group, affected_group
      assert_same site, changed_site
      assert_equal "picard", username
      assert_equal "livingston", password
    end
    site.add_login("picard", "livingston")
    assert called
  end

  test "after_login_added callback for hash-loaded group" do
    group = new_group({
      'name' => "Starships",
      'sites' => {
        'Enterprise' => {
          'name' => 'Enterprise',
          'logins' => {}
        }
      },
      'groups' => {}
    })
    site = group.site("Enterprise")

    called = false
    group.after_login_added do |affected_group, changed_site, username, password|
      called = true
      assert_same group, affected_group
      assert_same site, changed_site
      assert_equal "picard", username
      assert_equal "livingston", password
    end
    site.add_login("picard", "livingston")
    assert called
  end

  test "after_username_changed callback" do
    group = new_group("Starships")
    site = new_site("Enterprise")
    group.add_site(site)
    site.add_login("picard", "livingston")

    called = false
    group.after_username_changed do |affected_group, changed_site, old_username, new_username|
      called = true
      assert_same group, affected_group
      assert_same site, changed_site
      assert_equal "picard", old_username
      assert_equal "jean_luc", new_username
    end
    site.change_username("picard", "jean_luc")
    assert called
  end

  test "after_username_changed callback for hash-loaded group" do
    group = new_group({
      'name' => "Starships",
      'sites' => {
        'Enterprise' => {
          'name' => 'Enterprise',
          'logins' => {'picard' => 'livingston'}
        }
      },
      'groups' => {}
    })
    site = group.site("Enterprise")

    called = false
    group.after_username_changed do |affected_group, changed_site, old_username, new_username|
      called = true
      assert_same group, affected_group
      assert_same site, changed_site
      assert_equal "picard", old_username
      assert_equal "jean_luc", new_username
    end
    site.change_username("picard", "jean_luc")
    assert called
  end

  test "after_password_changed callback" do
    group = new_group("Starships")
    site = new_site("Enterprise")
    group.add_site(site)
    site.add_login("picard", "livingston")

    called = false
    group.after_password_changed do |affected_group, changed_site, username, old_password, new_password|
      called = true
      assert_same group, affected_group
      assert_same site, changed_site
      assert_equal "picard", username
      assert_equal "livingston", old_password
      assert_equal "crusher", new_password
    end
    site.change_password("picard", "crusher")
    assert called
  end

  test "after_password_changed callback for hash-loaded group" do
    group = new_group({
      'name' => "Starships",
      'sites' => {
        'Enterprise' => {
          'name' => 'Enterprise',
          'logins' => {'picard' => 'livingston'}
        }
      },
      'groups' => {}
    })
    site = group.site("Enterprise")

    called = false
    group.after_password_changed do |affected_group, changed_site, username, old_password, new_password|
      called = true
      assert_same group, affected_group
      assert_same site, changed_site
      assert_equal "picard", username
      assert_equal "livingston", old_password
      assert_equal "crusher", new_password
    end
    site.change_password("picard", "crusher")
    assert called
  end

  test "after_login_removed callback" do
    group = new_group("Starships")
    site = new_site("Enterprise")
    group.add_site(site)
    site.add_login("picard", "livingston")

    called = false
    group.after_login_removed do |affected_group, removed_site, username, password|
      called = true
      assert_same group, affected_group
      assert_same site, removed_site
      assert_equal "picard", username
      assert_equal "livingston", password
    end
    site.remove_login("picard")
    assert called
  end

  test "after_login_removed callback for hash-loaded group" do
    group = new_group({
      'name' => "Starships",
      'sites' => {
        'Enterprise' => {
          'name' => 'Enterprise',
          'logins' => {'picard' => 'livingston'}
        }
      },
      'groups' => {}
    })
    site = group.site("Enterprise")

    called = false
    group.after_login_removed do |affected_group, removed_site, username, password|
      called = true
      assert_same group, affected_group
      assert_same site, removed_site
      assert_equal "picard", username
      assert_equal "livingston", password
    end
    site.remove_login("picard")
    assert called
  end

  test "after_site_removed callback" do
    group = new_group("Starships")
    site = new_site("Enterprise")
    group.add_site(site)

    called = false
    group.after_site_removed do |affected_group, removed_site|
      called = true
      assert_same group, affected_group
      assert_same site, removed_site
    end
    group.remove_site("Enterprise")
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
    site = new_site("Enterprise")
    site.add_login("picard", "livingston")
    group.add_site(site)
    subgroup = new_group("Klingon")
    subsite = new_site("Bortas")
    subsite.add_login("gowron", "bat'leth")
    subgroup.add_site(subsite)
    group.add_group(subgroup)

    expected = {
      'name' => "Starships",
      'sites' => {
        "Enterprise" => {
          'name' => "Enterprise",
          'logins' => {"picard" => "livingston"}
        }
      },
      'groups' => {
        "Klingon" => {
          'name' => "Klingon",
          'sites' => {
            "Bortas" => {
              'name' => "Bortas",
              'logins' => {"gowron" => "bat'leth"}
            }
          },
          'groups' => {}
        }
      }
    }.to_yaml
    assert_equal expected, group.to_yaml
  end
end
