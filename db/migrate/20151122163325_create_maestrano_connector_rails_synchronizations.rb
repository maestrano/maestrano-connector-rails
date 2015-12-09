class CreateMaestranoConnectorRailsSynchronizations < ActiveRecord::Migration
  def change
    create_table :maestrano_connector_rails_synchronizations do |t|
      t.integer :organization_id
      t.string  :status
      t.text    :message
      t.boolean :partial, default: false

      t.timestamps null: false
    end
    add_index :maestrano_connector_rails_synchronizations, :organization_id, name: 'synchronization_orga_id_index'
  end
end
