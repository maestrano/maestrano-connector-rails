module Connector
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      source_root File.expand_path("../templates", __FILE__)

      def maestrano_generator
        #Temporary
        # generate 'maestrano:initializer'
      end

      def include_helpers
        sentinel = 'class ApplicationController < ActionController::Base'
        code_lines = [
          "helper Maestrano::Connector::Rails::Engine.helpers",
          "include Maestrano::Connector::Rails::SessionHelper"
        ]

        in_root do
          gsub_file 'app/controllers/application_controller.rb', /(#{Regexp.escape(sentinel)})/mi do |match|
            "#{match}\n  #{code_lines.join("\n  ")}\n"
          end
        end
      end

      def include_routes
        sentinel = 'Rails.application.routes.draw do'
        code_lines = [
          "mount Maestrano::Connector::Rails::Engine, at: '/'\n",
          "root 'home#index'",
          "get 'home/index' => 'home#index'",
          "get 'admin/index' => 'admin#index'",
          "put 'admin/update' => 'admin#update'",
          "post 'admin/synchronize' => 'admin#synchronize'",
          "put 'admin/toggle_sync' => 'admin#toggle_sync'"
        ]

        in_root do
          gsub_file 'config/routes.rb', /(#{Regexp.escape(sentinel)})/mi do |match|
            "#{match}\n  #{code_lines.join("\n  ")}\n"
          end
        end
      end

      def copy_entity
        copy_file 'entity.rb', 'app/models/maestrano/connector/rails/entity.rb'
      end

      def copy_external
        copy_file 'external.rb', 'app/models/maestrano/connector/rails/external.rb'
      end

      def copy_example_entity
        copy_file 'example_entity.rb', 'app/models/entities/example_entitiy.rb'
      end

      def copy_home
        copy_file 'home_controller.rb', 'app/controllers/home_controller.rb'
        copy_file 'home_index.html.erb', 'app/views/home/index.html.erb'
      end

      def copy_admin_view
        copy_file 'admin_controller.rb', 'app/controllers/admin_controller.rb'
        copy_file 'admin_index.html.erb', 'app/views/admin/index.html.erb'
      end

      def copy_oauth_controller
        copy_file 'oauth_controller.rb', 'app/controllers/oauth_controller.rb'
      end
    end
  end
end