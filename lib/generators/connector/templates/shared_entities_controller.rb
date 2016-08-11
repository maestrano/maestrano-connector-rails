class SharedEntitiesController < ApplicationController
  def index
    return unless is_admin
    @idmaps = Maestrano::Connector::Rails::IdMap.where(organization_id: current_organization.id).order(:connec_entity)
  end
end
