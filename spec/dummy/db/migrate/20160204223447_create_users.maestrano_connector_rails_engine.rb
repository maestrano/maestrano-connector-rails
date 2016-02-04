# This migration comes from maestrano_connector_rails_engine (originally 20151122162100)
class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :provider
      t.string :uid
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :tenant

      t.timestamps null: false
    end

    add_index :users, [:uid, :tenant], name: 'user_uid_index'
  end
end
