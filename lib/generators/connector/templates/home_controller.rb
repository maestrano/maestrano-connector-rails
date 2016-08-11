# frozen_string_literal: true
class HomeController < ApplicationController
  before_action :organization_to_update, only: [:update]

  def index
    @organization = current_organization
    @displayable_synchronized_entities = @organization.displayable_synchronized_entities if @organization
  end

  def update
    return redirect_to(:back) unless @updating_organization && is_admin?(current_user, @updating_organization)
    old_sync_state = @updating_organization.sync_enabled
    @updating_organization.synchronized_entities.keys.each do |entity|
      @updating_organization.synchronized_entities[entity] = params[entity.to_s].present?
    end
    @updating_organization.sync_enabled = @updating_organization.synchronized_entities.values.any?
    @updating_organization.check_historical_data(params['historical-data'].present?)

    unable_to_start = start_synchronization(old_sync_state, @updating_organization)

    redirect_to(:back) unless unable_to_start
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
      return redirect_to(:back), true unless !old_sync_state && organization.sync_enabled
      Maestrano::Connector::Rails::SynchronizationJob.perform_later(organization, {})
      flash[:info] = 'Congrats, you\'re all set up! Your data are now being synced'
      false
    end

    def organization_to_update
      @updating_organization = Maestrano::Connector::Rails::Organization.find_by_id(params[:id])
    end
end
