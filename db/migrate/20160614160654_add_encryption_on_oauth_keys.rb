class AddEncryptionOnOauthKeys < ActiveRecord::Migration
  def change
    tokens = Maestrano::Connector::Rails::Organization.map{|o|
      {id: o.id, oauth_token: o.oauth_token, refresh_token: o.refresh_token}
    }

    rename_column :organizations, :oauth_token, :encrypted_oauth_token
    add_column :organizations, :encrypted_oauth_token_iv, :string
    add_column :organizations, :encrypted_oauth_token_salt, :string
    rename_column :organizations, :refresh_token, :encrypted_refresh_token
    add_column :organizations, :encrypted_refresh_token_iv, :string
    add_column :organizations, :encrypted_refresh_token_salt, :string

    tokens.each do |token|
      o = Maestrano::Connector::Rails::Organization.find(token[:id])
      o.update(oauth_token: token[:oauth_token], refresh_token: token[:refresh_token])
    end
  end
end
