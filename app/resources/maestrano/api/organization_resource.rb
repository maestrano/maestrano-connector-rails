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

      filter :uid

      def account_linked?
        @model.oauth_uid.present?
      end

      alias has_account_linked account_linked?

      def account_creation_link
        Maestrano::Connector::Rails::External.create_account_link(@model || nil)
      end
    end
  end
end
