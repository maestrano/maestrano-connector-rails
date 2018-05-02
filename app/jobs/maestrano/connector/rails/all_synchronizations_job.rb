module Maestrano::Connector::Rails
  class AllSynchronizationsJob < ::ActiveJob::Base
    queue_as :default

    # Trigger synchronization of all active organizations
    def perform(name = nil, count = nil)
      active_organizations = Maestrano::Connector::Rails::Organization.where.not(oauth_provider: nil, encrypted_oauth_token: nil)
      gap_span = (60 / active_organizations.count).to_i
      time = 0
      active_organizations.each do |o|
        next unless [true, 1].include?(o.sync_enabled)
        Maestrano::Connector::Rails::SynchronizationJob.set(wait: time.minutes).perform_later(o.id, {})
        time += gap_span
      end
    end
  end
end
