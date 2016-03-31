class Maestrano::Account::GroupUsersController < Maestrano::Rails::WebHookController

  # DELETE /maestrano/account/groups/cld-1/users/usr-1
  # DELETE /maestrano/account/groups/cld-1/users/usr-1/tenant
  # Remove a user from a group
  def destroy
    # Set the right uid based on Maestrano.param('sso.creation_mode')
    user_uid = Maestrano.mask_user(params[:id], params[:group_id]) 
    group_uid = params[:group_id]
    
    # Get the entities
    user = Maestrano::Connector::Rails::User.find_by_uid_and_tenant(user_uid, params[:tenant] || 'default')
    organization = Maestrano::Connector::Rails::Organization.find_by_uid_and_tenant(group_uid, params[:tenant] || 'default')
    
    # Remove the user from the organization
    organization.remove_member(user)
    
    render json: {success: true}
  end
end