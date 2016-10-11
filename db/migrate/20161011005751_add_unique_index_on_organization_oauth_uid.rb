class AddUniqueIndexOnOrganizationOauthUid < ActiveRecord::Migration
  def change
    add_index :organizations, :oauth_uid, unique: true
  end
end
