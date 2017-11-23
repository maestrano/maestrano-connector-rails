module Connector
  class InstallGenerator < ::Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)
    desc 'Creating a Maestrano Connector application'

    def maestrano_generator
      generate 'maestrano:initializer'
    end

    def include_helpers
      sentinel = 'class ApplicationController < ActionController::Base'
      code_lines = [
        'include Maestrano::Connector::Rails::SessionHelper'
      ]

      in_root do
        gsub_file 'app/controllers/application_controller.rb', /(#{Regexp.escape(sentinel)})/mi do |match|
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
      copy_file 'example_entity_spec.rb', 'spec/models/entities/example_entitiy.rb'
    end

    def copy_icons_and_logos
      copy_file 'logos/to_connec.png', 'app/assets/images/logos/to_connec.png'
      copy_file 'logos/to_external.png', 'app/assets/images/logos/to_external.png'
    end

    def copy_controllers_and_views
      copy_file 'home_controller.rb', 'app/controllers/home_controller.rb'
      copy_file 'home_controller_spec.rb', 'spec/controllers/home_controller_spec.rb'
      copy_file 'home_index.haml', 'app/views/home/index.html.haml'
      copy_file 'home.js', 'app/assets/javascripts/home.js'

      copy_file 'synchronizations_controller.rb', 'app/controllers/synchronizations_controller.rb'
      copy_file 'synchronizations_controller_spec.rb', 'spec/controllers/synchronizations_controller_spec.rb'
      copy_file 'synchronizations_index.haml', 'app/views/synchronizations/index.html.haml'

      copy_file 'shared_entities_controller.rb', 'app/controllers/shared_entities_controller.rb'
      copy_file 'shared_entities_controller_spec.rb', 'spec/controllers/shared_entities_controller_spec.rb'
      copy_file 'shared_entities_index.haml', 'app/views/shared_entities/index.html.haml'

      copy_file 'layouts.haml', 'app/views/layouts/application.html.haml'

      mkdir_p 'app/controllers/maestrano/api'
      copy_file 'account_controller.rb', 'app/controllers/maestrano/api/account_controller.rb'
    end

    def copy_stylesheets
      copy_file 'stylesheets/application.sass', 'app/assets/stylesheets/application.sass'
      copy_file 'stylesheets/home.sass', 'app/assets/stylesheets/home.sass'
      copy_file 'stylesheets/layout.sass', 'app/assets/stylesheets/layout.sass'
      copy_file 'stylesheets/spacers.sass', 'app/assets/stylesheets/spacers.sass'
      copy_file 'stylesheets/variables.sass', 'app/assets/stylesheets/variables.sass'
    end

    def copy_oauth_controller
      copy_file 'oauth_controller.rb', 'app/controllers/oauth_controller.rb'
    end
  end
end
