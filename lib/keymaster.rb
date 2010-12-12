require 'openssl'

require 'rubygems'
require 'bundler/setup'

class Keymaster
  def initialize(config)
    @path = config[:path]
    @key = OpenSSL::PKey::RSA.new(File.read(config[:key]), config[:password])
    @data = File.exist?(@path) ? decrypt_database : {}
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
    File.open(@path, 'w') do |f|
      f.write(@key.public_encrypt(Marshal.dump(@data)))
    end
  end

  private
    def decrypt_database
      Marshal.load(@key.private_decrypt(File.read(@path)))
    end
end
