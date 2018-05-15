module Maestrano::Connector::Rails
  class AllSynchronizationsJob < ::ActiveJob::Base
    queue_as :default

    # Trigger synchronization of all active organizations
    def perform(name = nil, count = nil)
      active_organizations = Maestrano::Connector::Rails::Organization
                             .where.not(oauth_provider: nil, encrypted_oauth_token: nil)
                             .select { |o| [true, 1].include?(o.sync_enabled) }

      return true if active_organizations.count.zero?

      time_span_seconds = (3600 / active_organizations.count).to_i
      active_organizations.each_with_index do |organization, i|
        Maestrano::Connector::Rails::SynchronizationJob.set(wait: time_span_seconds * i).perform_later(organization.id, {})
      end
    end
  end
end
