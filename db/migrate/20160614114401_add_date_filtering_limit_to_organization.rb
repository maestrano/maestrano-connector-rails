class AddDateFilteringLimitToOrganization < ActiveRecord::Migration
  def change
    add_column :organizations, :date_filtering_limit, :datetime
  end
end
