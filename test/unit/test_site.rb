require 'helper'

class TestSite < Test::Unit::TestCase
  def new_site(*args)
    Keyrack::Site.new(*args)
  end

  test "creating new site" do
    site = new_site("Enterprise", "picard", "livingston")
    assert_equal "Enterprise", site.name
  end

  test "name setter" do
    site = new_site("Enterprise", "picard", "livingston")
    site.name = "NCC1701D"
    assert_equal "NCC1701D", site.name
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

  test "name change event" do
    site = new_site("Enterprise", "picard", "livingston")

    called = false
    site.after_event do |event|
      called = true
      assert_equal 'change', event.name
      assert_same site, event.owner
      assert_equal 'name', event.attribute_name
      assert_equal 'Enterprise', event.previous_value
      assert_equal 'NCC1701D', event.new_value
    end
    site.name = "NCC1701D"
    assert called
  end

  test "password changed callback" do
    site = new_site("Enterprise", "picard", "livingston")

    called = false
    site.after_event do |event|
      called = true
      assert_same site, event.owner
      assert_equal 'change', event.name
      assert_equal 'password', event.attribute_name
      assert_equal 'livingston', event.previous_value
      assert_equal 'crusher', event.new_value
    end
    site.password = "crusher"
    assert called
  end

  test "username changed callback" do
    site = new_site("Enterprise", "picard", "livingston")

    called = false
    site.after_event do |event|
      called = true
      assert_same site, event.owner
      assert_equal 'change', event.name
      assert_equal 'username', event.attribute_name
      assert_equal 'picard', event.previous_value
      assert_equal 'jean_luc', event.new_value
    end
    site.username = "jean_luc"
    assert called
  end

  test "to_h" do
    site = new_site("Enterprise", "picard", "livingston")
    expected = {
      'name' => 'Enterprise',
      'username' => 'picard',
      'password' => 'livingston'
    }
    assert_equal expected, site.to_h
  end

  test "sites with same name and username are equal" do
    site_1 = new_site("Enterprise", "picard", "livingston")
    site_2 = new_site("Enterprise", "picard", "crusher")
    site_3 = new_site("Enterprise", "jean_luc", "crusher")
    assert_equal site_1, site_2
    assert_not_equal site_1, site_3
  end
end
