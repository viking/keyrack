require 'openssl'
require 'rubygems'
require 'bundler/setup'
require 'net/scp'

class Keymaster
  def initialize(config)
    store_config = config[:store].dup
    @store = Store[store_config.delete(:type)].new(store_config)
    @key = OpenSSL::PKey::RSA.new(File.read(config[:key]), config[:password])
    @data = decrypt_database
  end

  def add(site, username, password)
    @data[site] = { :username => username, :password => password }
  end

  def get(site)
    @data[site]
  end

  def sites
    @data.keys
  end

  def save
    @store.write(@key.public_encrypt(Marshal.dump(@data)))
  end

  private
    def decrypt_database
      data = @store.read
      data ? Marshal.load(@key.private_decrypt(data)) : {}
    end
end

require File.dirname(__FILE__) + '/keymaster/store'
