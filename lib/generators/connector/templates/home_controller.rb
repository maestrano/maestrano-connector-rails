# frozen_string_literal: true
class HomeController < ApplicationController
  def index
    @organization = current_organization
    @displayable_synchronized_entities = @organization.displayable_synchronized_entities if @organization
  end

  def update
    organization = Maestrano::Connector::Rails::Organization.find_by_id(params[:id])

    return redirect_to(:back) unless organization && is_admin?(current_user, organization)
    old_sync_state = organization.sync_enabled
    organization.synchronized_entities.keys.each do |entity|
      organization.synchronized_entities[entity] = params[entity.to_s].present?
    end
    organization.sync_enabled = organization.synchronized_entities.values.any?
    organization.check_historical_data(params['historical-data'].present?)

    start_synchronization(old_sync_state, organization) unless !old_sync_state && organization.sync_enabled

    redirect_to(:back)
  end

  def synchronize
    return redirect_to(:back) unless is_admin
    Maestrano::Connector::Rails::SynchronizationJob.perform_later(current_organization, (params['opts'] || {}).merge(forced: true))
    flash[:info] = 'Synchronization requested'
    redirect_to(:back)
  end

  def redirect_to_external
    redirect_to 'https://path/to/external/app'
  end

  private

    def start_synchronization(old_sync_state, organization)
      Maestrano::Connector::Rails::SynchronizationJob.perform_later(organization, {})
      flash[:info] = 'Congrats, you\'re all set up! Your data are now being synced'
    end
end
