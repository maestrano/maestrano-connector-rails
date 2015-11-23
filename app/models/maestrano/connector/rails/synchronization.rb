module Maestrano::Connector::Rails
  class Synchronization < ActiveRecord::Base
    #===================================
    # Associations
    #===================================
    belongs_to :organization
  end
end