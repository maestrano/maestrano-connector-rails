# frozen_string_literal: true

module Maestrano
  module Api
    module Concerns
      module AccountController
        extend ActiveSupport::Concern

        #==================================================================
        # Included methods
        #==================================================================
        # 'included do' causes the included code to be evaluated in the
        # context where it is included rather than being executed in the
        # module's context
        included do
        end

        #==================================================================
        # Class methods
        #==================================================================
        module ClassMethods
        end

        #==================================================================
        # Instance methods
        #==================================================================
        def setup_form
          form = {
            schema: {
              type: 'object',
              properties: {
                array: {
                  title: 'You have not configured your schema form',
                  type: 'array',
                  items: {
                    type: 'string',
                    enum: [
                      "Ok I'll do it right away",
                      "I'll let someone else do it for me"
                    ]
                  }
                }
              }
            }
          }
          render json: form.to_json
        end

        def link_account
          render json: {error: 'Method to link account has not been implemented'}
        end

        def unlink_account
          organization = Maestrano::Connector::Rails::Organization.find_by(uid: params[:uid])
          organization.clear_omniauth
          render json: {status: 'ok'}.to_json
        end
      end
    end
  end
end
