class Maestrano::Connector::Rails::Entity
  include Maestrano::Connector::Rails::Concerns::Entity

  # Return an array of all the entities that the connector can synchronize
  # If you add new entities, you need to generate
  # a migration to add them to existing organizations
  def self.entities_list
    # TODO
    # By convention, entities name are returned as singular downcase connec one,
    # e.g %w(person, tasks_list)
  end

  # Return an array of entities from the external app
  def get_external_entities(client, last_synchronization, opts={})
    Rails.logger.info "Fetching #{@@external_name} #{self.external_entity_name.pluralize}"
    # TODO
    # This method should return only entities that have been updated since the last_synchronization
    # Rails.logger.info "Source=#{@@external_name}, Entity=#{self.external_entity_name}, Response=#{entities}"
  end

  def create_entity_to_external(client, mapped_connec_entity)
    Rails.logger.info "Create #{self.external_entity_name}: #{mapped_connec_entity} to #{@@external_name}"
    # TODO
    # This method creates the entity in the external app and returns the external id
  end

  def update_entity_to_external(client, mapped_connec_entity, external_id)
    Rails.logger.info "Update #{self.external_entity_name} (id=#{external_id}): #{mapped_connec_entity} to #{@@external_name}"
    # TODO
    # This method updates the entity with the given id in the external app
  end

  # * Discards entities that do not need to be pushed because they have not been updated since their last push
  # * Discards entities from one of the two source in case of conflict
  # * Maps not discarded entities and associates them with their idmap, or create one if there isn't any
  def consolidate_and_map_data(connec_entities, external_entities, organization)
    # TODO
    # This method iterates over both connec entities and external entities
    # One way of implementing it :

    # external_entities.map!{|entity|
    #   idmap = IdMap.find_by(external_id: ENTITY_ID, external_entity: self.external_entity_name, organization_id: organization.id)

    #   # No idmap: creating one, nothing else to do
    #   unless idmap
    #     next {entity: self.map_to_connec(entity), idmap: IdMap.create(external_id: ENTITY_ID, external_entity: self.external_entity_name, organization_id: organization.id)}
    #   end

    #   # Entity has not been modified since its last push to connec!
    #   next nil if idmap.last_push_to_connec && idmap.last_push_to_connec > ENTITY_LAST_UPDATE_DATE

    #   # Check for conflict with entities from connec!
    #   if idmap.connec_id && connec_entity = connec_entities.detect{|connec_entity| connec_entity['id'] == idmap.connec_id}
    #     # We keep the most recently updated entity
    #     if connec_entity['updated_at'] < ENTITY_LAST_UPDATE_DATE
    #       Rails.logger.info "Conflict between #{@@external_name} #{self.external_entity_name} #{entity} and Connec! #{self.connec_entity_name} #{connec_entity}. Entity from #{@@external_name} kept"
    #       connec_entities.delete(connec_entity)
    #       {entity: self.map_to_connec(entity), idmap: idmap}
    #     else
    #       Rails.logger.info "Conflict between #{@@external_name} #{self.external_entity_name} #{entity} and Connec! #{self.connec_entity_name} #{connec_entity}. Entity from Connec! kept"
    #       nil
    #     end
    #   end
    # }.compact!

    # The method map_to_external_with_idmap is provided by the gem
    # connec_entities.map!{|entity|
    #   self.map_to_external_with_idmap(entity, organization)
    # }.compact!
  end
end