module Maestrano::Connector::Rails

  # This class process the push to Connec, it use PushToConnecJob for retrocompatibility
  # By using sidekiq-unique-jobs, it makes sure that 2 calls on the same entity, are processed in order
  class PushToConnecWorker
    include Sidekiq::Worker
    sidekiq_options unique: :while_executing, unique_args: :unique_args

    def self.unique_args(args)
      organization = args[0]
      entities_hash = args[1]
      return[organization.id, entities_hash.keys.sort]
    end

    def perform(organization, entities_hash, opts={})
      PushToConnecJob.new.perform(organization, entities_hash, opts)
    end
  end
end