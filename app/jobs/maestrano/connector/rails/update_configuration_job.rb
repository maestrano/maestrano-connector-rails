module Maestrano::Connector::Rails
  class UpdateConfigurationJob < ::ActiveJob::Base
    include Maestrano::Connector::Rails::Concerns::UpdateConfigurationJob
  end
end
