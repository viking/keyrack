require 'helper'

class TestSite < Test::Unit::TestCase
  def new_site(arg)
    Keyrack::Site.new(arg)
  end

  test "creating new site" do
    site = new_site("Enterprise")
    assert_equal "Enterprise", site.name
  end

  test "add_login" do
    site = new_site("Enterprise")
    site.add_login("picard", "livingston")
    assert_equal({"picard" => "livingston"}, site.logins)
  end

  test "adding existing login raises error" do
    site = new_site("Enterprise")
    site.add_login("picard", "livingston")
    assert_raises(Keyrack::SiteError) do
      site.add_login("picard", "livingston")
    end
  end

  test "usernames" do
    site = new_site("Enterprise")
    site.add_login("picard", "livingston")
    assert_equal ["picard"], site.usernames
  end

  test "password_for" do
    site = new_site("Enterprise")
    site.add_login("picard", "livingston")
    assert_equal "livingston", site.password_for("picard")
  end

  test "getting password for non-existant username" do
    site = new_site("Enterprise")
    assert_raises(Keyrack::SiteError) do
      site.password_for("picard")
    end
  end

  test "change_password" do
    site = new_site("Enterprise")
    site.add_login("picard", "livingston")
    site.change_password("picard", "crusher")
    assert_equal({"picard" => "crusher"}, site.logins)
  end

  test "changing password for non-existant login raises error" do
    site = new_site("Enterprise")
    assert_raises(Keyrack::SiteError) do
      site.change_password("picard", "crusher")
    end
  end

  test "remove_login" do
    site = new_site("Enterprise")
    site.add_login("picard", "livingston")
    site.remove_login("picard")
    assert_equal({}, site.logins)
  end

  test "removing non-existant login raises error" do
    site = new_site("Enterprise")
    assert_raises(Keyrack::SiteError) do
      site.remove_login("picard")
    end
  end

  test "loading site from hash" do
    hash = {
      :name => "Enterprise",
      :logins => {"picard" => "livingston"}
    }
    site = new_site(hash)
    assert_equal "Enterprise", site.name
    assert_equal hash[:logins], site.logins
  end

  test "loading site from hash with missing name" do
    hash = {
      :logins => {"picard" => "livingston"}
    }
    assert_raises(ArgumentError) do
      site = new_site(hash)
    end
  end

  test "loading site from hash with non-string name" do
    hash = {
      :name => [123],
      :logins => {"picard" => "livingston"}
    }
    assert_raises(ArgumentError) do
      site = new_site(hash)
    end
  end

  test "loading site with missing logins" do
    hash = {
      :name => "Enterprise"
    }
    assert_raises(ArgumentError) do
      site = new_site(hash)
    end
  end

  test "loading site with non-hash logins" do
    hash = {
      :name => "Enterprise",
      :logins => "foo"
    }
    assert_raises(ArgumentError) do
      site = new_site(hash)
    end
  end

  test "loading site with invalid logins hash" do
    hash = {
      :name => "Enterprise",
      :logins => {[123] => [456]}
    }
    assert_raises(ArgumentError) do
      site = new_site(hash)
    end
  end
end
