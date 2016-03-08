class SynchronizationsController < ApplicationController
  def index
    if current_organization
      @synchronizations = Maestrano::Connector::Rails::Synchronization.where(organization_id: current_organization.id).order(updated_at: :desc).limit(40)
    end
  end
end