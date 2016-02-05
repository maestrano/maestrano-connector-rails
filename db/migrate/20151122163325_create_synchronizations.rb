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
