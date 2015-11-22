class CreateMaestranoConnectorRailsIdMaps < ActiveRecord::Migration
  def change
    create_table :maestrano_connector_rails_id_maps do |t|
      t.string :connec_id
      t.string :connec_entity
      t.string :external_id
      t.string :external_entity
      t.integer :organization_id

      t.timestamps null: false
    end
    add_index :maestrano_connector_rails_id_maps, [:connec_id, :connec_entity, :organization_id], name: 'idmap_connec_index'
    add_index :maestrano_connector_rails_id_maps, [:external_id, :external_entity, :organization_id], name: 'idmap_external_index'
    add_index :maestrano_connector_rails_id_maps, :organization_id, name: 'idmap_organization_index'
  end
end
