require 'helper'

class TestConfiguration < Test::Unit::TestCase
  test "load configuration with filesystem storage" do
    hash = {
      'store' => {
        'type' => 'filesystem',
        'path' => 'foo.db'
      }
    }
    YAML.expects(:load_file).with('/foo/bar').returns(hash)
    conf = Keyrack::Configuration.load("/foo/bar")
    assert_kind_of Keyrack::Configuration, conf

    store = stub('store')
    Keyrack::Store::Filesystem.expects(:new).with('path' => 'foo.db').returns(store)
    assert_same store, conf.store
  end

  test "load configuration with ssh storage" do
    hash = {
      'store' => {
        'type' => 'ssh',
        'host' => 'localhost',
        'user' => 'bro',
        'pass' => 'dudebro',
        'path' => 'foo.db'
      }
    }
    YAML.expects(:load_file).with('/foo/bar').returns(hash)
    conf = Keyrack::Configuration.load("/foo/bar")
    assert_kind_of Keyrack::Configuration, conf

    store = stub('store')
    Keyrack::Store::SSH.expects(:new).with({
      'host' => 'localhost',
      'user' => 'bro',
      'pass' => 'dudebro',
      'path' => 'foo.db'
    }).returns(store)
    assert_same store, conf.store
  end

  test "create configuration" do
    conf = Keyrack::Configuration.new

    store = stub('store')
    store.expects(:options).returns({'foo' => 'bar'})
    store.expects(:type).returns('baz')
    conf.store = store
    assert_same store, conf.store

    expected = {
      'store' => {
        'type' => 'baz',
        'foo' => 'bar'
      }
    }
    assert_equal expected, conf.options

    file = stub('file')
    File.expects(:open).with('/foo/bar', 'w').yields(file)
    file.expects(:write).with(expected.to_yaml)
    conf.save('/foo/bar')
  end
end
