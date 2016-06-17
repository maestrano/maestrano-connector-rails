class AddDateFilteringLimitToOrganization < ActiveRecord::Migration
  def change
    add_column :organizations, :date_filtering_limit, :datetime
    add_column :organizations, :historical_data, :boolean, default: false

    # Set historical data to true for organization existing before the feature
    Maestrano::Connector::Rails::Organization.all.each do |o|
      o.update(historical_data: true)
    end
  end
end
