module Maestrano::Connector::Rails
  class AllSynchronizationsJob < ::ActiveJob::Base
    queue_as :default

    # Trigger synchronization of all active organizations
    def perform(name = nil, count = nil)
      Maestrano::Connector::Rails::Organization
        .where.not(oauth_provider: nil, encrypted_oauth_token: nil)
        .where(sync_enabled: true)
        .select(:id)
        .find_each do |organization|
        Maestrano::Connector::Rails::SynchronizationJob.set(wait: rand(3600)).perform_later(organization.id, {})
      end
    end
  end
end
