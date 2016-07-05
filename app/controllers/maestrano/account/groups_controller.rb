class Maestrano::Account::GroupsController < Maestrano::Rails::WebHookController
  # DELETE /maestrano/account/groups/cld-1/tenant
  # Delete an entire group
  def destroy
    # id
    org_uid = params[:id]

    # Get entity
    organization = Maestrano::Connector::Rails::Organization.find_by_uid_and_tenant(org_uid, params[:tenant] || 'default')

    # Delete all relations
    organization.user_organization_rels.delete_all

    # Delete the organization
    organization.destroy

    # Respond
    render json: {success: true}
  end
end
