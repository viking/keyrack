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

    expected = {"Klingon" => {:name => "Klingon", :sites => {}, :groups => {}}}
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
      :name => "Starships",
      :sites => {
        "Enterprise" => {
          :name => "Enterprise",
          :logins => {"picard" => "livingston"}
        }
      },
      :groups => {
        "Klingon" => {
          :name => "Klingon",
          :sites => {
            "Bortas" => {
              :name => "Bortas",
              :logins => {"gowron" => "bat'leth"}
            }
          },
          :groups => {}
        }
      }
    }
    group = new_group(hash)
    assert_equal "Starships", group.name
    assert_equal hash[:sites], group.sites
    assert_equal hash[:groups], group.groups
  end

  test "loading group from hash with missing name" do
    hash = {
      :sites => {},
      :groups => {}
    }
    assert_raises(ArgumentError) do
      group = new_group(hash)
    end
  end

  test "loading group from hash with non-string name" do
    hash = {
      :name => [123],
      :sites => {},
      :groups => {}
    }
    assert_raises(ArgumentError) do
      group = new_group(hash)
    end
  end

  test "loading group with missing sites" do
    hash = {
      :name => "Starships",
      :groups => {}
    }
    assert_raises(ArgumentError) do
      group = new_group(hash)
    end
  end

  test "loading group with non-hash sites" do
    hash = {
      :name => "Starships",
      :sites => "foo",
      :groups => {}
    }
    assert_raises(ArgumentError) do
      group = new_group(hash)
    end
  end

  test "loading group with non-string site name" do
    hash = {
      :name => "Starships",
      :sites => {
        [123] => {
          :name => "Enterprise",
          :logins => {"picard" => "livingston"}
        }
      },
      :groups => {}
    }
    assert_raises(ArgumentError) do
      group = new_group(hash)
    end
  end

  test "loading group with non-hash site value" do
    hash = {
      :name => "Starships",
      :sites => {
        "foo" => "foo"
      },
      :groups => {}
    }
    assert_raises(ArgumentError) do
      group = new_group(hash)
    end
  end

  test "loading group with invalid site" do
    hash = {
      :name => "Starships",
      :sites => {
        "foo" => {"foo" => "bar"}
      },
      :groups => {}
    }
    assert_raises(ArgumentError) do
      group = new_group(hash)
    end
  end

  test "loading group with mismatched site names" do
    hash = {
      :name => "Starships",
      :sites => {
        "Foo" => {
          :name => "Enterprise",
          :logins => {"picard" => "livingston"}
        }
      },
      :groups => {}
    }
    assert_raises(ArgumentError) do
      group = new_group(hash)
    end
  end

  test "loading group with missing groups" do
    hash = {
      :name => "Starships",
      :sites => {}
    }
    assert_raises(ArgumentError) do
      group = new_group(hash)
    end
  end

  test "loading group with non-hash groups" do
    hash = {
      :name => "Starships",
      :sites => {},
      :groups => "foo"
    }
    assert_raises(ArgumentError) do
      group = new_group(hash)
    end
  end

  test "loading group with non-string group name" do
    hash = {
      :name => "Starships",
      :sites => {},
      :groups => {
        [123] => {
          :name => "Klingon",
          :sites => {},
          :groups => {}
        }
      },
    }
    assert_raises(ArgumentError) do
      group = new_group(hash)
    end
  end

  test "loading group with non-hash group value" do
    hash = {
      :name => "Starships",
      :sites => {},
      :groups => {
        "foo" => "bar"
      }
    }
    assert_raises(ArgumentError) do
      group = new_group(hash)
    end
  end

  test "loading group with invalid sub-group" do
    hash = {
      :name => "Starships",
      :sites => {},
      :groups => {
        "foo" => {"foo" => "bar"}
      }
    }
    assert_raises(ArgumentError) do
      group = new_group(hash)
    end
  end

  test "loading group with mismatched group names" do
    hash = {
      :name => "Starships",
      :sites => {},
      :groups => {
        "Foo" => {
          :name => "Klingon",
          :sites => {},
          :groups => {}
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
end
