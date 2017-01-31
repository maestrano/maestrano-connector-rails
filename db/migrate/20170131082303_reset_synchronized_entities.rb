class ResetSynchronizedEntities < ActiveRecord::Migration
  def change
  	# Set historical data to true for organization existing before the feature
    Maestrano::Connector::Rails::Organization.all.each do |o|
      o.reset_synchronized_entities
    end
  end
end
