module Maestrano
  module Api
    class OrganizationResource < BaseResource
      @model_class = Maestrano::Connector::Rails::Organization

      # == Attributes ===========================================================
      attribute :name
      attribute :has_account_linked
      attribute :uid
      attribute :org_uid

      filter :uid

      def account_linked?
        @model.oauth_uid.present?
      end

      alias has_account_linked account_linked?
    end
  end
end
