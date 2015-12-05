# TODO
# This controller is given as an example of a possible home
# Admin funcitons :
# * Display generic information about the connector (mostly for not connected users)
# * Link the connector to a Maestrano organization
# * Acces the last synchronization and a synchronization history (with their status)
class HomeController < ApplicationController
  def index
    if current_user
      @organization = current_organization

      if @organization
        @synchronizations = Maestrano::Connector::Rails::Synchronization.where(organization_id: @organization.id).order(updated_at: :desc).limit(40)
      end
    end
  end
end