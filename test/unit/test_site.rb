require 'helper'

class TestSite < Test::Unit::TestCase
  def new_site(*args)
    Keyrack::Site.new(*args)
  end

  test "creating new site" do
    site = new_site("Enterprise", "picard", "livingston")
    assert_equal "Enterprise", site.name
  end

  test "username" do
    site = new_site("Enterprise", "picard", "livingston")
    assert_equal "picard", site.username
  end

  test "username setter" do
    site = new_site("Enterprise", "picard", "livingston")
    site.username = "jean_luc"
    assert_equal "jean_luc", site.username
  end

  test "password" do
    site = new_site("Enterprise", "picard", "livingston")
    assert_equal "livingston", site.password
  end

  test "password setter" do
    site = new_site("Enterprise", "picard", "livingston")
    site.password = "crusher"
    assert_equal "crusher", site.password
  end

  test "loading site from hash" do
    hash = {
      'name' => 'Enterprise',
      'username' => 'picard',
      'password' => 'livingston'
    }
    site = new_site(hash)
    assert_equal 'Enterprise', site.name
    assert_equal 'picard', site.username
    assert_equal 'livingston', site.password
  end

  test "loading site from hash with missing name" do
    hash = {
      'username' => 'picard',
      'password' => 'livingston'
    }
    assert_raises(ArgumentError) do
      site = new_site(hash)
    end
  end

  test "loading site from hash with non-string name" do
    hash = {
      'name' => [123],
      'username' => 'picard',
      'password' => 'livingston'
    }
    assert_raises(ArgumentError) do
      site = new_site(hash)
    end
  end

  test "loading site from hash with missing username" do
    hash = {
      'name' => 'Enterprise',
      'password' => 'livingston'
    }
    assert_raises(ArgumentError) do
      site = new_site(hash)
    end
  end

  test "loading site from hash with non-string username" do
    hash = {
      'name' => 'Enterprise',
      'username' => [123],
      'password' => 'livingston'
    }
    assert_raises(ArgumentError) do
      site = new_site(hash)
    end
  end

  test "loading site from hash with missing password" do
    hash = {
      'name' => 'Enterprise',
      'username' => 'picard'
    }
    assert_raises(ArgumentError) do
      site = new_site(hash)
    end
  end

  test "loading site from hash with non-string password" do
    hash = {
      'name' => 'Enterprise',
      'username' => 'picard',
      'password' => [123]
    }
    assert_raises(ArgumentError) do
      site = new_site(hash)
    end
  end

  test "after_password_changed callback" do
    site = new_site("Enterprise", "picard", "livingston")

    called = false
    site.after_password_changed do |affected_site|
      called = true
      assert_same site, affected_site
      assert_equal "crusher", affected_site.password
    end
    site.password = "crusher"
    assert called
  end

  test "after_username_changed callback" do
    site = new_site("Enterprise", "picard", "livingston")

    called = false
    site.after_username_changed do |affected_site|
      called = true
      assert_same site, affected_site
      assert_equal "jean_luc", affected_site.username
    end
    site.username = "jean_luc"
    assert called
  end

  test "serializing to yaml" do
    site = new_site("Enterprise", "picard", "livingston")
    expected = {
      'name' => 'Enterprise',
      'username' => 'picard',
      'password' => 'livingston'
    }.to_yaml
    assert_equal expected, site.to_yaml
  end

  test "sites with same name and username are equal" do
    site_1 = new_site("Enterprise", "picard", "livingston")
    site_2 = new_site("Enterprise", "picard", "crusher")
    site_3 = new_site("Enterprise", "jean_luc", "crusher")
    assert_equal site_1, site_2
    assert_not_equal site_1, site_3
  end
end
