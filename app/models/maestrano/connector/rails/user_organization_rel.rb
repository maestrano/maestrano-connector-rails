module Maestrano
  module Connector
    module Rails


      class UserOrganizationRel < ActiveRecord::Base
        #===================================
        # Associations
        #===================================
        belongs_to :user
        belongs_to :organization
      end


    end
  end
end