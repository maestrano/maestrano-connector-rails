module Maestrano::Connector::Rails
  class IdMap < ActiveRecord::Base
    include Maestrano::Connector::Rails::Concerns::IdMap
  end
end
