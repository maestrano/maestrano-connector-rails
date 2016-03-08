class SharedEntitiesController < ApplicationController
  def index
    if is_admin
      @idmaps = Maestrano::Connector::Rails::IdMap.where(organization_id: current_organization.id).order(:connec_entity)
    end
  end
end