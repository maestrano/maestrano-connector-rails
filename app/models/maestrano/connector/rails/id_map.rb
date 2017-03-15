module Maestrano::Connector::Rails
  class IdMap < ActiveRecord::Base
    belongs_to :organization
    serialize :metadata, Hash
  end
end
