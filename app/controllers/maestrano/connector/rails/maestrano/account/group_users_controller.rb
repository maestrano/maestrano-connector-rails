module Maestrano
  module Connector
    module Rails


      class Maestrano::Account::GroupUsersController < Maestrano::Rails::WebHookController

        # DELETE /maestrano/account/groups/cld-1/users/usr-1
        # Remove a user from a group
        def destroy
          # Set the right uid based on Maestrano.param('sso.creation_mode')
          user_uid = Maestrano.mask_user(params[:id],params[:group_id])
          group_uid = params[:group_id]

          user = User.find_by_provider_and_uid('maestrano',user_uid)
          organization = Organization.find_by_provider_and_uid('maestrano',group_uid)
          organization.remove_user(user)

          render json: {success: true}
        end
      end


    end
  end
end