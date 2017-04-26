module Maestrano::Connector::Rails
  class Organization < ActiveRecord::Base
    include Maestrano::Connector::Rails::Concerns::Organization
  end
end
