module Maestrano
  module Connector
    module Rails


      class Synchronization < ActiveRecord::Base
        #===================================
        # Associations
        #===================================
        belongs_to :organization
      end


    end
  end
end