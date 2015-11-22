class CreateMaestranoConnectorRailsOrganizations < ActiveRecord::Migration
  def change
    create_table :maestrano_connector_rails_organizations do |t|
      t.string :provider
      t.string :uid
      t.string :name
      t.string :tenant

      t.string :oauth_provider
      t.string :oauth_uid
      t.string :oauth_token
      t.string :refresh_token
      t.string :instance_url

      t.timestamps null: false
    end
    add_index :maestrano_connector_rails_organizations, [:uid, :tenant], name: 'orga_uid_index'
  end
end
