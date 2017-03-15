class AddMetadataToIdMap < ActiveRecord::Migration
  def change
  	add_column :id_maps, :metadata, :text
  end
end
