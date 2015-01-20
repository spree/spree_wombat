require 'simplecov'
SimpleCov.start do
  add_group 'Models', '/app/models/'
  add_group 'Controllers', '/app/controllers/'
  add_group 'Serializers', '/app/serializers/'
  add_group "Wombat", '/lib/spree/wombat/'
  add_group 'Handlers', '/lib/spree/wombat/handler/'

  add_filter '/spec/'

  project_name 'Webhooks and Push API implemention for Wombat'
end

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'

begin
  require File.expand_path("../dummy/config/environment", __FILE__)
rescue LoadError
  puts "Could not load dummy application. Please ensure you have run `bundle exec rake test_app`"
  exit
end

require 'rspec/rails'
require 'rspec/autorun'
require 'database_cleaner'
require 'ffaker'
require 'hub/samples'
require 'timecop'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each {|f| require f}

require 'spree/testing_support/controller_requests'
require 'spree/testing_support/factories'
require 'spree/testing_support/preferences'
require 'active_model/serializer'

RSpec.configure do |config|
  config.backtrace_exclusion_patterns = [/gems\/activesupport/, /gems\/actionpack/, /gems\/rspec/]
  config.color = true
  config.infer_spec_type_from_file_location!

  config.include FactoryGirl::Syntax::Methods
  config.include Spree::TestingSupport::Preferences, type: :controller
  config.include Spree::TestingSupport::ControllerRequests, type: :controller

  config.fail_fast = ENV['FAIL_FAST'] || false

  config.use_transactional_fixtures = false

  config.after do
    DatabaseCleaner.clean
  end

  config.before do
    HTTParty.stub :post
    Spree::Wombat::Config[:connection_token] = "abc1233"

    DatabaseCleaner.start
  end

  config.before :suite do
    DatabaseCleaner.strategy = :deletion
    DatabaseCleaner.clean_with :truncation
  end

  config.mock_with :rspec do |mocks|
    mocks.yield_receiver_to_any_instance_implementation_blocks = true
  end
end

class Spree::Wombat::Handler::MyCustomHandler < Spree::Wombat::Handler::Base
  def process
    response "Order added!"
  end
end

class CustomSerializer < ActiveModel::Serializer
  attributes :name
  def name
    "#{object.id} : #{object.name}"
  end
end
