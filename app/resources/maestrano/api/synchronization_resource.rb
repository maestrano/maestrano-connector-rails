module Maestrano
  module Api
    class SynchronizationResource < BaseResource
      @model_class = Maestrano::Connector::Rails::Synchronization

      # == Attributes ===========================================================
      attribute :status
      attribute :message
      attribute :updated_at
      attribute :created_at

      belongs_to :organization

      filter :uid, apply: lambda { |records, value, _options|
        records.joins(:organization).where('organizations.uid = ?', value)
      }
    end
  end
end
