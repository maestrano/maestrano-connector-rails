module Maestrano::Connector::Rails
  class IdMap < ActiveRecord::Base
  	self.table_name = "maestrano_connector_rails_id_maps"

    belongs_to :organization
  end
end