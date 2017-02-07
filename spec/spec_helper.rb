ENV['RAILS_ENV'] ||= 'test'

require File.expand_path('../dummy/config/environment.rb',  __FILE__)
require 'rspec/rails'
require 'factory_girl_rails'
require 'shoulda/matchers'
require 'simplecov'
require 'timecop'
require 'maestrano_connector_rails/factories.rb'
require 'webmock/rspec'
SimpleCov.start

Rails.backtrace_cleaner.remove_silencers!

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.mock_with :rspec
  config.use_transactional_fixtures = true
  config.infer_base_class_for_anonymous_controllers = false
  config.order = 'random'
  config.include FactoryGirl::Syntax::Methods
  config.include Maestrano::Connector::Rails::Engine.routes.url_helpers

  config.before(:each) do
    allow(Maestrano::Connector::Rails::External).to receive(:external_name).and_return('External app')
    allow(Maestrano::Connector::Rails::External).to receive(:get_client).and_return(Object.new)
    allow(Maestrano::Connector::Rails::External).to receive(:entities_list).and_return(%w(entity1 entity2))
    stub_request(:get, %r(#{Maestrano['default'].param('api.host')}/api/v1/account/groups/[\w-]*)).
      to_return({status: 200, body: "{}", headers: {}})
    Rails.cache.clear
  end
end
