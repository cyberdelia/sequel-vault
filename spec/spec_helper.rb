require 'bundler'
Bundler.require

require 'simplecov'
SimpleCov.start do
  add_filter('spec/')
end

require 'sequel'
require 'sequel_vault'

RSpec.configure do |config|
  config.order = 'random'

  config.before(:suite) do
    Sequel.connect('sqlite:/')
  end

  config.around do |example|
    Sequel::Model.db.transaction(rollback: :always) { example.run }
  end
end
