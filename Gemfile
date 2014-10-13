source 'https://rubygems.org'

gem 'spree', github: 'spree/spree', branch: "2-4-stable"

gem 'coffee-rails', '~> 4.0.0'
gem 'sass-rails', '~> 4.0.0'

gem 'pg'

group :test do
  gem 'hub_samples', github: "spree/hub_samples", branch: "master"
  gem 'timecop'

  platforms :ruby_19 do
    gem 'pry-debugger'
  end
  platforms :ruby_20, :ruby_21 do
    gem 'pry-byebug'
  end
end

gemspec
