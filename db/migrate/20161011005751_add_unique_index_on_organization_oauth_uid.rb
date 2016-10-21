class AddUniqueIndexOnOrganizationOauthUid < ActiveRecord::Migration
  def change
    # Disconnect accounts linked several times
    execute <<-SQL
      -- DELETE FROM indicator WHERE name IN ('RATING_COEFF_MIXED', 'RATING_COEFF_MIXED_BEST3')
      UPDATE organizations AS o
      INNER JOIN
        (SELECT organizations.oauth_uid, min(organizations.id) minid FROM organizations GROUP BY oauth_uid) o1
        ON o.oauth_uid = o1.oauth_uid AND o.id != o1.minid
      SET o.oauth_uid = null, o.encrypted_oauth_token = null, encrypted_refresh_token= null, sync_enabled = false
    SQL

    add_index :organizations, :oauth_uid, unique: true
  end
end
