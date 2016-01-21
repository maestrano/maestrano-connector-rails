class Maestrano::Account::GroupsController < Maestrano::Rails::WebHookController
  
  # DELETE /maestrano/account/groups/cld-1
  # DELETE /maestrano/account/groups/cld-1/tenant
  # Delete an entire group
  def destroy
    # id
    group_uid = params[:id]
    
    # Get entity
    organization = Organization.find_by_provider_and_uid_and_tenant('maestrano', group_uid, params[:tenant])
    
    # Delete all relations
    organization.user_company_rels.delete_all
    
    # Delete the organization
    organization.destroy
    
    # Respond
    render json: {success: true}
  end
end