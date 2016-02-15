class AddNameToIdMap < ActiveRecord::Migration
  def change
    add_column :id_maps, :to_connec, :boolean, default: true
    add_column :id_maps, :to_external, :boolean, default: true
    add_column :id_maps, :name, :string
    add_column :id_maps, :message, :string
  end
end
