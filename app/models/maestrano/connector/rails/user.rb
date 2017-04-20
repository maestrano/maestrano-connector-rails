module Maestrano::Connector::Rails
  class User < ActiveRecord::Base
    include Maestrano::Connector::Rails::Concerns::User
  end
end
