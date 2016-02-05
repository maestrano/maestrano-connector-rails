# This migration comes from maestrano_connector_rails_engine (originally 20151122163449)
class CreateIdMaps < ActiveRecord::Migration
  def change
    create_table :id_maps do |t|
      t.string :connec_id
      t.string :connec_entity
      t.string :external_id
      t.string :external_entity
      t.integer :organization_id
      t.datetime :last_push_to_connec
      t.datetime :last_push_to_external

      t.timestamps null: false
    end
    add_index :id_maps, [:connec_id, :connec_entity, :organization_id], name: 'idmap_connec_index'
    add_index :id_maps, [:external_id, :external_entity, :organization_id], name: 'idmap_external_index'
    add_index :id_maps, :organization_id, name: 'idmap_organization_index'
  end
end
