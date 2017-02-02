class UpdateOrganizationMetadata < ActiveRecord::Migration
  def change
  	add_column :organizations, :push_disabled, :boolean
  	add_column :organizations, :pull_disabled, :boolean
  	# Migration to update the way we handle synchronized_entities for data sharing.
	  # Before : synchronized_entities = {company: true}
	  # After: synchronized_entities = {company: {can_push_to_connec: true, can_push_to_external: true}}

	  #We also add metadata from MnoHub
    Maestrano::Connector::Rails::Organization.all.each do |o|
      o.set_instance_metadata
      o.reset_synchronized_entities
    end
  end
end
