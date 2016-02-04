# This migration comes from maestrano_connector_rails_engine (originally 20151122162613)
class CreateUserOrganizationRels < ActiveRecord::Migration
  def change
    create_table :user_organization_rels do |t|
      t.integer :user_id
      t.integer :organization_id

      t.timestamps
    end
    add_index :user_organization_rels, :organization_id, name: 'rels_orga_index'
    add_index :user_organization_rels, :user_id, name: 'rels_user_index'
  end
end
