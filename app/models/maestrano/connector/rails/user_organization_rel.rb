module Maestrano::Connector::Rails
  class UserOrganizationRel < ActiveRecord::Base
  	self.table_name = "maestrano_connector_rails_user_organization_rels"

    #===================================
    # Associations
    #===================================
    belongs_to :user
    belongs_to :organization
  end
end