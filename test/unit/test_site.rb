require 'helper'

class TestSite < Test::Unit::TestCase
  def new_site(name)
    Keyrack::Site.new(name)
  end

  test "initialization" do
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
end
