class Maestrano::Connector::Rails::Entity < Maestrano::Connector::Rails::EntityBase
  include Maestrano::Connector::Rails::Concerns::Entity

  # In this class and in all entities which inherit from it, the following instance variables are available:
  # * @organization
  # * @connec_client
  # * @external_client
  # * @opts

  # Return an array of entities from the external app
  def get_external_entities(last_synchronization_date=nil)
    Maestrano::Connector::Rails::ConnectorLogger.log('info', @organization, "Fetching #{Maestrano::Connector::Rails::External.external_name} #{self.class.external_entity_name.pluralize}")
    # TODO
    # This method should return only entities that have been updated since the last_synchronization_date
    # It should also implements an option to do a full synchronization when @opts[:full_sync] == true or when there is no last_synchronization_date
    # It should also support [:__limit] and [:__skip] opts, meaning that if they are present, it should return only @[:__limit] entities while skipping the @opts[:__skip] firsts
    # Maestrano::Connector::Rails::ConnectorLogger.log('info', @organization, "Received data: Source=#{Maestrano::Connector::Rails::External.external_name}, Entity=#{self.class.external_entity_name}, Response=#{entities}")
  end

  def create_external_entity(mapped_connec_entity, external_entity_name)
    Maestrano::Connector::Rails::ConnectorLogger.log('info', @organization, "Sending create #{external_entity_name}: #{mapped_connec_entity} to #{Maestrano::Connector::Rails::External.external_name}")
    # TODO
    # This method creates the entity in the external app and returns the external id
  end

  def update_external_entity(mapped_connec_entity, external_id, external_entity_name)
    Maestrano::Connector::Rails::ConnectorLogger.log('info', @organization, "Sending update #{external_entity_name} (id=#{external_id}): #{mapped_connec_entity} to #{Maestrano::Connector::Rails::External.external_name}")
    # TODO
    # This method updates the entity with the given id in the external app
  end

  def self.id_from_external_entity_hash(entity)
    # TODO
    # This method return the id from an external_entity_hash
    # e.g entity['id']
  end

  def self.last_update_date_from_external_entity_hash(entity)
    # TODO
    # This method return the last update date from an external_entity_hash
    # e.g entity['last_update']
  end

  def self.creation_date_from_external_entity_hash(entity)
    # TODO
    # This method return the creation date from an external_entity_hash
    # e.g entity['created_at']
  end

  def self.inactive_from_external_entity_hash?(entity)
    # TODO
    # This method return true is entity is inactive in the external application
    # e.g entity['status'] == 'INACTIVE'
  end

end