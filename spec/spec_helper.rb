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

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each {|f| require f}

# Requires factories defined in spree_core
require 'spree/core/testing_support/factories'
require 'spree/core/testing_support/controller_requests'
require 'spree/core/testing_support/authorization_helpers'
require 'spree/core/url_helpers'
require 'active_model/serializer'


RSpec.configure do |config|
  config.backtrace_exclusion_patterns = [/gems\/activesupport/, /gems\/actionpack/, /gems\/rspec/]
  config.color = true


  config.include Spree::Core::TestingSupport::Preferences, :type => :controller
  config.include Spree::Core::TestingSupport::ControllerRequests, :type => :controller

  config.include FactoryGirl::Syntax::Methods
  # == URL Helpers
  #
  # Allows access to Spree's routes in specs:
  #
  # visit spree.admin_path
  # current_path.should eql(spree.products_path)
  config.include Spree::Core::UrlHelpers

  config.fail_fast = ENV['FAIL_FAST'] || false

  config.use_transactional_fixtures = false

  config.before(:suite) do
    DatabaseCleaner.strategy = :deletion
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

  config.before do
    HTTParty.stub :post
    Spree::Wombat::Config[:connection_token] = "abc1233"
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
