# frozen_string_literal: true
class Maestrano::Connector::Rails::Entity < Maestrano::Connector::Rails::EntityBase
  include Maestrano::Connector::Rails::Concerns::Entity

  # In this class and in all entities which inherit from it, the following instance variables are available:
  # * @organization
  # * @connec_client
  # * @external_client
  # * @opts

  # This method should return only entities that have been updated since the last_synchronization_date
  # It should also implements an option to do a full synchronization when @opts[:full_sync] == true or when there is no last_synchronization_date
  # It should also support [:__limit] and [:__skip] opts, meaning that if they are present, it should return only @[:__limit] entities while skipping the @opts[:__skip] firsts
  # Return an array of entities from the external app
  def get_external_entities(external_entity_name, last_synchronization_date = nil)
    Maestrano::Connector::Rails::ConnectorLogger.log('info', @organization, "Fetching #{Maestrano::Connector::Rails::External.external_name} #{self.class.external_entity_name.pluralize}")
    # Maestrano::Connector::Rails::ConnectorLogger.log('info', @organization, "Received data: Source=#{Maestrano::Connector::Rails::External.external_name}, Entity=#{self.class.external_entity_name}, Response=#{entities}")
    # TODO
  end

  # This method creates the entity in the external app and returns the created external entity
  def create_external_entity(mapped_connec_entity, external_entity_name)
    Maestrano::Connector::Rails::ConnectorLogger.log('info', @organization, "Sending create #{external_entity_name}: #{mapped_connec_entity} to #{Maestrano::Connector::Rails::External.external_name}")
    # TODO
  end

  # This method updates the entity with the given id in the external app and returns the created external entity
  def update_external_entity(mapped_connec_entity, external_id, external_entity_name)
    Maestrano::Connector::Rails::ConnectorLogger.log('info', @organization, "Sending update #{external_entity_name} (id=#{external_id}): #{mapped_connec_entity} to #{Maestrano::Connector::Rails::External.external_name}")
    # TODO
  end

  # This method return the id from an external_entity_hash
  # e.g entity['id']
  def self.id_from_external_entity_hash(entity)
    # TODO
  end

  # This method return the last update date from an external_entity_hash
  # e.g entity['last_update']
  def self.last_update_date_from_external_entity_hash(entity)
    # TODO
  end

  # This method return the creation date from an external_entity_hash
  # e.g entity['created_at']
  def self.creation_date_from_external_entity_hash(entity)
    # TODO
  end

  # This method return true is entity is inactive in the external application
  # e.g entity['status'] == 'INACTIVE'
  def self.inactive_from_external_entity_hash?(entity)
    # TODO
  end

  # This method return true if entity is immutable.
  # An entity is immutable, if it is only ever created, but never updated. eg. BankTransaction
  def self.immutable?(entity)
    # TODO
  end
end
