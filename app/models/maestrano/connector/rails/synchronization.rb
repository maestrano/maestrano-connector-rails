module Maestrano::Connector::Rails
  class Synchronization < ActiveRecord::Base
    include Maestrano::Connector::Rails::Concerns::Synchronization
  end
end
