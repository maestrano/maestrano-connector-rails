class Maestrano::Account::GroupsController < Maestrano::Rails::WebHookController
  # DELETE /maestrano/account/groups/cld-1/tenant
  # Delete an entire group
  def destroy
    # id
    org_uid = params[:id]

    # Get entity
    organization = Maestrano::Connector::Rails::Organization.find_by(uid: org_uid, tenant: params[:tenant] || 'default')

    unless organization
      Maestrano::Connector::Rails::ConnectorLogger.log('info', nil, 'Organization not found')
      return render json: {success: true}, status: :no_content
    end

    Maestrano::Connector::Rails::ConnectorLogger.log('info', organization, 'delete organization')

    # Delete all relations
    organization.user_organization_rels.delete_all

    # Delete the organization
    organization.destroy

    # Respond
    render json: {success: true}
  end
end
