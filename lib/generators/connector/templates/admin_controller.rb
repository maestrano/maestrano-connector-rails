# TODO
# This controller is given as an example of a possible admin implementation
# The admin functions should be restricted to admin users
# Admin funcitons :
#  * Link account to external application
#  * Disconnect account from external application
#  * Launch a manual syncrhonization for all entities or a sub-part of them
#  * Chose which entities are synchronized by the connector
#  * Access a list of the organization's idmaps
class AdminController < ApplicationController

  def index
    if is_admin
      @organization = current_organization
      @idmaps = Maestrano::Connector::Rails::IdMap.where(organization_id: @organization.id).order(:connec_entity)
    end
  end

  def update
    organization = Maestrano::Connector::Rails::Organization.find_by_id(params[:id])

    if organization && is_admin?(current_user, organization)
      organization.synchronized_entities.keys.each do |entity|
        if !!params["#{entity}"]
          organization.synchronized_entities[entity] = true
        else
          organization.synchronized_entities[entity] = false
        end
      end
      organization.save
    end

    redirect_to admin_index_path
  end

  def synchronize
    if is_admin
      Maestrano::Connector::Rails::SynchronizationJob.perform_later(current_organization, params['opts'] || {})
    end

    redirect_to root_path
  end

  def toggle_sync
    if is_admin
      current_organization = Maestrano::Connector::Rails::Organization.first
      current_organization.update(sync_enabled: !current_organization.sync_enabled)
    end

    redirect_to admin_index_path
  end

  private
    def is_admin
      current_user && current_organization && is_admin?(current_user, current_organization)
    end
end