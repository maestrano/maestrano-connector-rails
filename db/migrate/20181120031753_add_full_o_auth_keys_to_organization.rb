class AddFullOAuthKeysToOrganization < ActiveRecord::Migration
  def change
    add_column :organizations, :encrypted_oauth_keys, :test
    add_column :organizations, :encrypted_oauth_keys_iv, :string
  end
end
