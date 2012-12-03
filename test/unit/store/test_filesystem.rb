require 'helper'

module Keyrack
  module Store
    class TestFilesystem < Test::Unit::TestCase
      def test_read
        path = fixture_path('foo.txt')
        store = Filesystem.new('path' => path)
        assert_equal File.read(path), store.read
      end

      def test_write
        path = get_tmpname
        store = Filesystem.new('path' => path)
        store.write("foobar")
        assert_equal "foobar", File.read(path)
      end

      def test_read_returns_nil_for_non_existant_file
        store = Filesystem.new('path' => 'blargityblargh')
        assert_nil store.read
      end
    end
  end
end
