class AddEncryptionOnOauthKeys < ActiveRecord::Migration
  def change
    rename_column :organizations, :oauth_token, :encrypted_oauth_token
    add_column :organizations, :encrypted_oauth_token_iv, :string
    add_column :organizations, :encrypted_oauth_token_salt, :string
    rename_column :organizations, :refresh_token, :encrypted_refresh_token
    add_column :organizations, :encrypted_refresh_token_iv, :string
    add_column :organizations, :encrypted_refresh_token_salt, :string
  end
end
