class AddUniqueIndexOnOrganizationOauthUid < ActiveRecord::Migration
  def change
    # Disconnect accounts linked several times
    if ActiveRecord::Base.connection.class.to_s == 'ActiveRecord::ConnectionAdapters::Mysql2Adapter'
      execute <<-SQL
        UPDATE organizations AS o
        INNER JOIN
          (SELECT organizations.oauth_uid, min(organizations.id) minid FROM organizations GROUP BY oauth_uid) o1
          ON o.oauth_uid = o1.oauth_uid AND o.id != o1.minid
        SET o.oauth_uid = null, o.encrypted_oauth_token = null, encrypted_refresh_token= null, sync_enabled = false
      SQL
    end

    add_index :organizations, :oauth_uid, unique: true
  end
end
