# frozen_string_literal: true

require 'simplecov'
SimpleCov.start

ENV['RAILS_ENV'] ||= 'test'

require File.expand_path('../config/environment', __dir__)
require 'rspec/rails'
require 'factory_girl_rails'
require 'shoulda/matchers'
require 'maestrano_connector_rails/factories.rb'
require 'webmock/rspec'

Rails.backtrace_cleaner.remove_silencers!

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.mock_with :rspec
  config.use_transactional_fixtures = true
  config.infer_base_class_for_anonymous_controllers = false
  config.order = 'random'
  config.include FactoryGirl::Syntax::Methods
  config.before(:each) do
    stub_request(:get, %r{https://maestrano.com/api/v1/account/groups/\w+})
      .with(headers: {'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Authorization' => 'Basic Og==', 'User-Agent' => 'Ruby'})
      .to_return(status: 200, body: '{}', headers: {})
  end
end
