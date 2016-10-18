class AddOrgUidToOrganization < ActiveRecord::Migration
  def change
    add_column :organizations, :org_uid, :string
  end
end
