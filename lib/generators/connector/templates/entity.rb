class Maestrano::Connector::Rails::Entity
  include Maestrano::Connector::Rails::Concerns::Entity

  # Return an array of all the entities that the connector can synchronize
  # If you add new entities, you need to generate
  # a migration to add them to existing organizations
  def self.entities_list
    # TODO
    # The names in this list should match the names of your entities class
    # e.g %w(person, tasks_list)
    #  will synchronized Entities::Person and Entities::TasksList
    []
  end

  # Return an array of entities from the external app
  def get_external_entities(client, last_synchronization, organization, opts={})
    Maestrano::Connector::Rails::ConnectorLogger.log('info', organization, "Fetching #{@@external_name} #{self.external_entity_name.pluralize}")
    # TODO
    # This method should return only entities that have been updated since the last_synchronization
    # It should also implements an option to do a full synchronization when opts[:full_sync] == true or when there is no last_synchronization
    # Maestrano::Connector::Rails::ConnectorLogger.log('info', organization, "Received data: Source=#{@@external_name}, Entity=#{self.external_entity_name}, Response=#{entities}")
  end

  def create_external_entity(client, mapped_connec_entity, external_entity_name, organization)
    Maestrano::Connector::Rails::ConnectorLogger.log('info', organization, "Sending create #{external_entity_name}: #{mapped_connec_entity} to #{@@external_name}")
    # TODO
    # This method creates the entity in the external app and returns the external id
  end

  def update_external_entity(client, mapped_connec_entity, external_id, external_entity_name, organization)
    Maestrano::Connector::Rails::ConnectorLogger.log('info', organization, "Sending update #{external_entity_name} (id=#{external_id}): #{mapped_connec_entity} to #{@@external_name}")
    # TODO
    # This method updates the entity with the given id in the external app
  end

  def get_id_from_external_entity_hash(entity)
    # TODO
    # This method return the id from an external_entity_hash
    # e.g entity['id']
  end

  def get_last_update_date_from_external_entity_hash(entity)
    # TODO
    # This method return the last update date from an external_entity_hash
    # e.g entity['last_update']
  end

end