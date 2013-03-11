require 'helper'

class TestEvent < Test::Unit::TestCase
  test "initialize with owner and name" do
    obj = stub('object')
    event = Keyrack::Event.new(obj, 'change')
    assert_equal obj, event.owner
    assert_equal 'change', event.name
  end

  test "initialize with parent event" do
    child = stub('child object')
    event_1 = Keyrack::Event.new(child, 'change')
    assert_nil event_1.parent

    parent = stub('parent object')
    event_2 = Keyrack::Event.new(parent, 'change', event_1)
    assert_equal event_1, event_2.parent
  end

  test "attribute details" do
    obj = stub('object')
    event = Keyrack::Event.new(obj, 'change')
    event.attribute_name = "foo"
    assert_equal "foo", event.attribute_name
    event.previous_value = "bar"
    assert_equal "bar", event.previous_value
    event.new_value = "baz"
    assert_equal "baz", event.new_value
  end

  test "collection details" do
    owner = stub('owner')
    event = Keyrack::Event.new(owner, 'add')
    event.collection_name = "foo"
    assert_equal "foo", event.collection_name
    obj = stub('object')
    event.object = obj
    assert_equal obj, event.object
  end
end
