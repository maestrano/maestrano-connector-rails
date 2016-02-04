# This migration comes from maestrano_connector_rails_engine (originally 20151122162414)
class CreateOrganizations < ActiveRecord::Migration
  def change
    create_table :organizations do |t|
      t.string :provider
      t.string :uid
      t.string :name
      t.string :tenant

      t.string :oauth_provider
      t.string :oauth_uid
      t.string :oauth_token
      t.string :refresh_token
      t.string :instance_url

      t.string :synchronized_entities

      t.timestamps null: false
    end
    add_index :organizations, [:uid, :tenant], name: 'orga_uid_index'
  end
end
