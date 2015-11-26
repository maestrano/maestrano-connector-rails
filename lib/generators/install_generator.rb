module Generators
  class InstallGenerator < ::Rails::Generators::Base
    source_root File.expend_path("../templates", __FILE__)

    def copy_entity
      template 'entity.rb', 'app/models/maestrano/connector/rails/entity.rb'
    end

    def copy_external
      template 'external.rb', 'app/models/maestrano/connector/rails/external.rb'
    end

    def copy_example_entity
      template 'example_entity.rb', 'app/models/entities/example_entitiy.rb'
    end

    def copy_home_view
      template 'home_index.html.erb', 'app/views/home/index.html.erb'
    end

    def copy_admin_view
      template 'admin_index.html.erb', 'app/views/admin/index.html.erb'
    end
  end
end