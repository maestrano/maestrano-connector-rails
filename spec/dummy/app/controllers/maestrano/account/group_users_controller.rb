class Maestrano::Account::GroupUsersController < Maestrano::Rails::WebHookController

  # DELETE /maestrano/account/groups/cld-1/users/usr-1
  # Remove a user from a group
  def destroy
    # Set the right uid based on Maestrano.param('sso.creation_mode')
    user_uid = Maestrano.mask_user(params[:id],params[:group_id]) 
    group_uid = params[:group_id]
    
    # Perform association deletion steps here
    # --
    # If Maestrano.param('sso.creation_mode') is set to virtual
    # then you might want to just delete/cancel/block the user
    #
    # E.g
    # user = User.find_by_provider_and_uid('maestrano',user_uid)
    # organization = Organization.find_by_provider_and_uid('maestrano',group_uid)
    # 
    # if Maestrano.param('sso.creation_mode') == 'virtual'
    #  user.destroy
    # else
    #   organization.remove_user(user)
    #   user.block_access! if user.reload.organizations.empty?
    # end
  end
end