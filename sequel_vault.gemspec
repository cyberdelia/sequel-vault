# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.authors       = ["Timothée Peignier"]
  gem.email         = ["timothee.peignier@tryphon.org"]
  gem.description   = %q{Sequel plugins to handle encrypted attributes}
  gem.summary       = %q{Handle attributes encryption.}
  gem.homepage      = "http://rubygems.org/gems/sequel_vault"
  gem.license       = 'MIT'

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "sequel_vault"
  gem.require_paths = ["lib"]
  gem.version       = '0.5'

  gem.add_runtime_dependency 'sequel', '~> 4.21', '>= 4.21.0'
  gem.add_runtime_dependency 'fernet', '~> 2.1', '>= 2.1'

  gem.add_development_dependency 'rspec', '~> 3.2', '>= 3.2.0'
  gem.add_development_dependency 'simplecov', '~> 0.9.2'
  gem.add_development_dependency 'sqlite3', '~> 1.3', '>= 1.3.10'
end
