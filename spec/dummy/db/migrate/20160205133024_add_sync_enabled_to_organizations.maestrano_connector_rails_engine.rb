# This migration comes from maestrano_connector_rails_engine (originally 20160205132857)
class AddSyncEnabledToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :sync_enabled, :boolean, default: false
  end
end
