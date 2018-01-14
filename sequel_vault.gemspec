Gem::Specification.new do |gem|
  gem.authors       = ['Timothée Peignier']
  gem.email         = ['timothee.peignier@tryphon.org']
  gem.description   = 'Sequel plugins to handle encrypted attributes'
  gem.summary       = 'Handle attributes encryption.'
  gem.homepage      = 'http://rubygems.org/gems/sequel_vault'
  gem.license       = 'MIT'

  gem.files         = `git ls-files`.split($OUTPUT_RECORD_SEPARATOR)
  gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = 'sequel_vault'
  gem.require_paths = ['lib']
  gem.version       = '0.5.2'

  gem.add_runtime_dependency 'fernet', '~> 2.3', '>= 2.3'
  gem.add_runtime_dependency 'sequel', '>= 4.39.0'

  gem.add_development_dependency 'rspec', '~> 3.5', '>= 3.5.0'
  gem.add_development_dependency 'rubocop', '~> 0.52', '>= 0.52.0'
  gem.add_development_dependency 'rubocop-rspec', '~> 1.22', '>= 1.22.0'
  gem.add_development_dependency 'simplecov', '~> 0.15.0'
  gem.add_development_dependency 'sqlite3', '~> 1.3', '>= 1.3.10'
end
