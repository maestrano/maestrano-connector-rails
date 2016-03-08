class HomeController < ApplicationController
  def index
    @organization = current_organization
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

    redirect_to(:back)
  end

  def synchronize
    if is_admin
      Maestrano::Connector::Rails::SynchronizationJob.perform_later(current_organization, params['opts'] || {})
      flash[:info] = 'Synchronization requested'
    end

    redirect_to(:back)
  end

  def toggle_sync
    if is_admin
      current_organization.update(sync_enabled: !current_organization.sync_enabled)
      flash[:info] = current_organization.sync_enabled ? 'Synchronization enabled' : 'Synchronization disabled'
    end

    redirect_to(:back)
  end
end