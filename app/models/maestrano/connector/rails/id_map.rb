module Maestrano::Connector::Rails
  class IdMap < ActiveRecord::Base

    belongs_to :organization
  end
end