module Maestrano::Connector::Rails::Concerns::IdMap
  extend ActiveSupport::Concern

  included do
    belongs_to :organization
    serialize :metadata, Hash
  end
end
