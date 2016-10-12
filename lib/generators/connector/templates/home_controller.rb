# frozen_string_literal: true
class HomeController < ApplicationController
  def update
    return redirect_to(:back) unless is_admin

    # Update list of entities to synchronize
    current_organization.synchronized_entities.keys.each do |entity|
      current_organization.synchronized_entities[entity] = params[entity.to_s].present?
    end
    current_organization.sync_enabled = current_organization.synchronized_entities.values.any?
    current_organization.enable_historical_data(params['historical-data'].present?)
    trigger_sync = current_organization.sync_enabled && current_organization.sync_enabled_changed?
    current_organization.save

    # Trigger sync only if the sync has been enabled
    start_synchronization if trigger_sync

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

    def start_synchronization
      Maestrano::Connector::Rails::SynchronizationJob.perform_later(current_organization.id, {})
      flash[:info] = 'Congrats, you\'re all set up! Your data are now being synced'
    end
end
