class Maestrano::Account::GroupUsersController < Maestrano::Rails::WebHookController

  # DELETE /maestrano/account/groups/cld-1/users/usr-1
  # DELETE /maestrano/account/groups/cld-1/users/usr-1/tenant
  # Remove a user from a group
  def destroy
    # Set the right uid based on Maestrano.param('sso.creation_mode')
    user_uid = Maestrano.mask_user(params[:id], params[:group_id]) 
    group_uid = params[:group_id]
    
    # Get the entities
    user = User.find_by_provider_and_uid_and_tenant('maestrano', user_uid, params[:tenant])
    organization = Organization.find_by_provider_and_uid_and_tenant('maestrano', group_uid, params[:tenant])
    
    # Remove the user from the organization
    organization.remove_member(user)
    
    render json: {success: true}
  end
end