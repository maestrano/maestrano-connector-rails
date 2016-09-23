module Maestrano::Connector::Rails
  class AllSynchronizationsJob < ::ActiveJob::Base
    queue_as :default

    # Trigger synchronization of all active organizations
    def perform(name = nil, count = nil)
      Maestrano::Connector::Rails::Organization.where.not(oauth_provider: nil, encrypted_oauth_token: nil).each do |o|
        next unless [true, 1].include?(o.sync_enabled)
        Maestrano::Connector::Rails::SynchronizationJob.perform_later(o.id, {})
      end
    end
  end
end
