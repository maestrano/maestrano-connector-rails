module Maestrano
  module Connector
    module Rails

      class Maestrano::Account::GroupsController < Maestrano::Rails::WebHookController

        # DELETE /maestrano/account/groups/cld-1
        # Delete an entire group
        def destroy
          group_uid = params[:id]

          organization = Organization.find_by_provider_and_uid('maestrano',group_uid)
          organization.destroy

          render json: {success: true}
        end
      end


    end
  end
end