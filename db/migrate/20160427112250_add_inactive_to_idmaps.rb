class AddInactiveToIdmaps < ActiveRecord::Migration
  def change
    add_column :id_maps, :external_inactive, :boolean, default: false
  end
end