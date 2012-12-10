# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'keyrack/version'

Gem::Specification.new do |gem|
  gem.name          = "keyrack"
  gem.version       = Keyrack::VERSION
  gem.authors       = ["Jeremy Stephens"]
  gem.email         = ["viking@pillageandplunder.net"]
  gem.description   = %q{Simple password manager with local/remote database storage and scrypt encryption.}
  gem.summary       = %q{Simple password manager}
  gem.homepage      = "http://github.com/viking/keyrack"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency 'net-scp'
  gem.add_runtime_dependency 'highline'
  gem.add_runtime_dependency 'clipboard'
  gem.add_runtime_dependency 'scrypty'

  gem.add_development_dependency 'bundler'
  gem.add_development_dependency 'mocha'
  gem.add_development_dependency 'test-unit'
end
