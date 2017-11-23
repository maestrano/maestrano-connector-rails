module Maestrano
  module Api
    class ApiController < JSONAPI::ResourceController
      protect_from_forgery
      before_action :authenticate_client!

      # Return the current API client (tenant)
      attr_accessor :client

      def context
        {client: client, params: params, current_user: client, policy_used: -> { @policy_used = true }}
      end

      protected

        def current_user
          @client
        end

        def authorize(record, query = nil)
          context[:policy_used]&.call
          super
        end

      private

        def authenticate_client!
          authenticate_tenant || unauthorized!
        end

        def unauthorized!
          head :unauthorized
        end

        def authenticate_tenant
          @client = authenticate_with_http_basic do |api_key, api_secret|
            Maestrano.find_by_app_id_and_app_key(api_key, api_secret)
          end
        end
    end
  end
end
