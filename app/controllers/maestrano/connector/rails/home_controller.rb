module Maestrano::Connector::Rails
  class HomeController < ApplicationController
    def index
      if current_user
        @organization = current_organization

        if @organization
          @synchronizations = Synchronization.where(organization_id: @organization.id).order(updated_at: :desc).limit(40)
        end
      end
    end
  end
end