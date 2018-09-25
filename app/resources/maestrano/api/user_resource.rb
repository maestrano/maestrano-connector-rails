module Maestrano
  module Api
    class UserResource < BaseResource
      @model_class = Maestrano::Connector::Rails::User

      # == Attributes ===========================================================
      attribute :first_name
      attribute :provider
      attribute :last_name
      attribute :email
      attribute :tenant
      attribute :uid

      def save
        @model.tenant = context[:client]
        super
        return unless org_uid == context.dig(:params, :org_uid)

        org = Maestrano::Connector::Rails::Organization.find_by(org_uid: org_uid)
        org.add_member(@model) unless !org || org.member?(@model)
      end
    end
  end
end
