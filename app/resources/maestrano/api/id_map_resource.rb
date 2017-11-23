module Maestrano
  module Api
    class IdMapResource < BaseResource
      @model_class = Maestrano::Connector::Rails::IdMap

      # == Attributes ===========================================================
      attribute :connec_id
      attribute :external_entity
      attribute :external_id
      attribute :name
      attribute :message

      all_filters

      filter :uid, apply: lambda { |records, value, _options|
        records.joins(:organization).where('organizations.uid = ?', value)
      }
      filter :external_entity

      has_many :synchronizations

      def account_linked?
        @model.oauth_uid.present?
      end

      alias has_account_linked account_linked?

      def account_creation_link
        Maestrano::Connector::Rails::External.create_account_link(@model || nil)
      end

      def save
        @model.tenant = context[:client]
        super
      end
    end
  end
end
