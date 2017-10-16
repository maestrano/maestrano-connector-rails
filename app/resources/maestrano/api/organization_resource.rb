module Maestrano
  module Api
    class OrganizationResource < BaseResource
      @model_class = Maestrano::Connector::Rails::Organization

      # == Attributes ===========================================================
      attribute :name
      attribute :has_account_linked
      attribute :uid
      attribute :org_uid
      attribute :account_creation_link
      attribute :displayable_synchronized_entities
      attribute :date_filtering_limit
      attribute :tenant
      attribute :provider
      attribute :sync_enabled

      filter :uid

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
