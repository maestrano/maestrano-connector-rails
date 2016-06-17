class HomeController < ApplicationController
  def index
    @organization = current_organization
  end

  def update
    organization = Maestrano::Connector::Rails::Organization.find_by_id(params[:id])

    if organization && is_admin?(current_user, organization)
      old_sync_state = organization.sync_enabled

      organization.synchronized_entities.keys.each do |entity|
        organization.synchronized_entities[entity] = !!params["#{entity}"]
      end
      organization.sync_enabled = organization.synchronized_entities.values.any?

      unless organization.historical_data
        historical_data = !!params['historical-data']
        if historical_data
          organization.date_filtering_limit = nil
          organization.historical_data = true
        else
          organization.date_filtering_limit ||= Time.now
        end
      end
      
      organization.save

      if !old_sync_state && organization.sync_enabled
        Maestrano::Connector::Rails::SynchronizationJob.perform_later(organization, {})
        flash[:info] = 'Congrats, you\'re all set up! Your data are now being synced'
      end
    end

    redirect_to(:back)
  end

  def synchronize
    if is_admin
      Maestrano::Connector::Rails::SynchronizationJob.perform_later(current_organization, (params['opts'] || {}).merge(forced: true))
      flash[:info] = 'Synchronization requested'
    end

    redirect_to(:back)
  end

  def redirect_to_external
    redirect_to 'https://path/to/external/app'
  end

end