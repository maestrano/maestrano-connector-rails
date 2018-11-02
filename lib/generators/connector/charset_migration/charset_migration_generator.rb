# frozen_string_literal: true

require 'rails/generators/named_base'
require 'rails/generators/active_record/migration'

module Connector
  module Generators
    class CharsetMigrationGenerator < ::Rails::Generators::Base
      include ActiveRecord::Generators::Migration

      source_root File.expand_path('templates', __dir__)

      def copy_migration
        migration_template "migration.rb", "db/migrate/convert_tables_to_utf8.rb"
      end
    end
  end
end
