# frozen_string_literal: true
class HomeController < ApplicationController
  def index
    @organization = current_organization
    @displayable_synchronized_entities = @organization.displayable_synchronized_entities if @organization
  end

  def update
    organization = Maestrano::Connector::Rails::Organization.find_by_id(params[:id])
    return redirect_to(:back) unless organization && is_admin?(current_user, organization)

    # Update list of entities to synchronize
    organization.synchronized_entities.keys.each do |entity|
      organization.synchronized_entities[entity] = params[entity.to_s].present?
    end
    organization.sync_enabled = organization.synchronized_entities.values.any?
    organization.enable_historical_data(params['historical-data'].present?)
    trigger_sync = organization.sync_enabled && organization.sync_enabled_changed?
    organization.save

    # Trigger sync only if the sync has been enabled
    start_synchronization(organization) if trigger_sync

    redirect_to(:back)
  end

  def synchronize
    return redirect_to(:back) unless is_admin
    Maestrano::Connector::Rails::SynchronizationJob.perform_later(current_organization.id, (params['opts'] || {}).merge(forced: true))
    flash[:info] = 'Synchronization requested'
    redirect_to(:back)
  end

  # Implement the redirection to the external application
  def redirect_to_external
    redirect_to 'https://path/to/external/app'
  end

  private

    def start_synchronization(organization)
      Maestrano::Connector::Rails::SynchronizationJob.perform_later(organization.id, {})
      flash[:info] = 'Congrats, you\'re all set up! Your data are now being synced'
    end
end
