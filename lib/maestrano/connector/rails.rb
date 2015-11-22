require 'maestrano'

module Maestrano
  module Connector
    module Rails


      class Engine < ::Rails::Engine
        isolate_namespace Maestrano::Connector::Rails
      end


    end
  end
end