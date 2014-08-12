source 'https://rubygems.org'

gem 'spree', github: 'spree/spree', branch: "1-3-stable"

group :test, :development do
  gem 'hub_samples', github: "spree/hub_samples", branch: "master"

  platforms :ruby_19 do
    gem 'pry-debugger'
  end
  platforms :ruby_20, :ruby_21 do
    gem 'pry-byebug'
  end
end

gemspec
