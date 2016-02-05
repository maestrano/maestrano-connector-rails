class AddSyncEnabledToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :sync_enabled, :boolean, default: false
  end
end
