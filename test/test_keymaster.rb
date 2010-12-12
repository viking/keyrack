require 'helper'

class TestKeymaster < Test::Unit::TestCase
  def setup
    @path = get_tmpname
    @keymaster = Keymaster.new({
      :path => @path,
      :key => fixture_path('id_rsa'),
      :password => 'secret'
    })
    @keymaster.add('Twitter', 'username', 'password')
    @keymaster.save
  end

  def get_tmpname
    tmpname = Dir::Tmpname.create('keymaster') { }
    @tmpnames ||= []
    @tmpnames << tmpname
    tmpname
  end

  def teardown
    if @tmpnames
      @tmpnames.each { |t| File.unlink(t) }
    end
  end

  def test_encrypts_database
    key = OpenSSL::PKey::RSA.new(File.read(fixture_path('id_rsa')), 'secret')
    encrypted_data = File.read(@path)
    marshalled_data = key.private_decrypt(encrypted_data)
    data = Marshal.load(marshalled_data)
    assert_equal({'Twitter'=>{:username=>'username',:password=>'password'}}, data)
  end

  def test_reading_existing_database
    keymaster = Keymaster.new({
      :path => @path,
      :key => fixture_path('id_rsa'),
      :password => 'secret'
    })
    expected = {:username => 'username', :password => 'password'}
    assert_equal(expected, keymaster.get('Twitter'))
  end

  def test_sites
    assert_equal(%w{Twitter}, @keymaster.sites)
  end
end
