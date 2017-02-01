class ResetSynchronizedEntities < ActiveRecord::Migration
  def change
	# Migration to update the way we handle synchronized_entities for data sharing.
	# Before : synchronized_entities = {company: true}
	# After: synchronized_entities = {company: {can_push_to_connec: true, can_push_to_external: true}}
    Maestrano::Connector::Rails::Organization.all.each do |o|
      o.reset_synchronized_entities
    end
  end
end
