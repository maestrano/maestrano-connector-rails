require 'maestrano'
require 'maestrano-rails'
require 'hash_mapper'

module Maestrano
  module Connector
    module Rails


      class Engine < ::Rails::Engine
        isolate_namespace Maestrano::Connector::Rails
      end


    end
  end
end