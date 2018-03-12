# Periodically fetch the developer platform configuration
module Maestrano::Connector::Rails::Concerns::UpdateConfigurationJob
  extend ActiveSupport::Concern

  included do
    queue_as :default
  end

  def perform
    return if ENV['SKIP_CONFIGURATION']
    Maestrano.reset!
    Maestrano.auto_configure
  rescue StandardError => e
    Rails.logger.warn "Cannot load configuration #{e.message}"
  end
end
