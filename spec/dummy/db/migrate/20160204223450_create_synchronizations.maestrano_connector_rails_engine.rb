# This migration comes from maestrano_connector_rails_engine (originally 20151122163325)
class CreateSynchronizations < ActiveRecord::Migration
  def change
    create_table :synchronizations do |t|
      t.integer :organization_id
      t.string  :status
      t.text    :message
      t.boolean :partial, default: false

      t.timestamps null: false
    end
    add_index :synchronizations, :organization_id, name: 'synchronization_orga_id_index'
  end
end
