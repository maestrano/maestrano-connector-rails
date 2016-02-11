module Maestrano::Connector::Rails
  class AllSynchronizationsJob < ::ActiveJob::Base
    queue_as :default

    # Trigger synchronization of all active organizations
    def perform(name=nil, count=nil)
      Maestrano::Connector::Rails::Organization.where("oauth_provider IS NOT NULL AND oauth_token IS NOT NULL").each do |o|
        next unless [true, 1].include?(o.sync_enabled)
        Maestrano::Connector::Rails::SynchronizationJob.perform_later(o, {})
      end
    end
  end
end