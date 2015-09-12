# encoding: UTF-8
Gem::Specification.new do |gem|
  gem.authors       = ["Peter Berkenbosch"]
  gem.email         = ["peter@spreecommerce.com"]
  gem.summary       = "Webhooks and Push API implemention for Wombat"
  gem.description   = gem.summary
  gem.homepage      = "http://wombat.co"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "spree_wombat"
  gem.require_paths = ["lib"]
  gem.version       = '2.2.0'

  gem.add_dependency 'spree_core', '~> 3.0.0'
  gem.add_dependency 'active_model_serializers', '0.9.0.alpha1'
  gem.add_dependency 'httparty'

  gem.add_development_dependency 'capybara', '~> 2.1'
  gem.add_development_dependency 'coffee-rails', '~> 4.0.0'
  gem.add_development_dependency 'database_cleaner', '~> 1.3.0' # 1.4.0 is broken https://github.com/DatabaseCleaner/database_cleaner/issues/317
  gem.add_development_dependency 'factory_girl', '~> 4.4'
  gem.add_development_dependency 'ffaker'
  gem.add_development_dependency 'mysql2'
  gem.add_development_dependency 'pg'
  gem.add_development_dependency 'rspec-rails',  '~> 2.13'
  gem.add_development_dependency 'sass-rails', '~> 5.0.0'
  gem.add_development_dependency 'selenium-webdriver'
  gem.add_development_dependency 'simplecov'
  gem.add_development_dependency 'sqlite3'
  gem.add_development_dependency 'timecop'
end
