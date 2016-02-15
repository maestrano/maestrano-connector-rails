module Maestrano::Connector::Rails::Concerns::Entity
  extend ActiveSupport::Concern

  module ClassMethods
    # Return an array of all the entities that the connector can synchronize
    # If you add new entities, you need to generate
    # a migration to add them to existing organizations
    def entities_list
      raise "Not implemented"
    end
  end

  @@external_name = Maestrano::Connector::Rails::External.external_name

  # ----------------------------------------------
  #                 Mapper methods
  # ----------------------------------------------
  # Map a Connec! entity to the external format
  def map_to_external(entity, organization)
    self.mapper_class.normalize(entity)
  end

  # Map an external entity to Connec! format
  def map_to_connec(entity, organization)
    self.mapper_class.denormalize(entity)
  end

  # ----------------------------------------------
  #                 Connec! methods
  # ----------------------------------------------
  def get_connec_entities(client, last_synchronization, organization, opts={})
    Maestrano::Connector::Rails::ConnectorLogger.log('info', organization, "Fetching Connec! #{self.connec_entity_name}")

    entities = []

    # Fetch first page
    if last_synchronization.blank? || opts[:full_sync]
      Maestrano::Connector::Rails::ConnectorLogger.log('debug', organization, "entity=#{self.connec_entity_name}, fetching all data")
      response = client.get("/#{self.connec_entity_name.downcase.pluralize}")
    else
      Maestrano::Connector::Rails::ConnectorLogger.log('debug', organization, "entity=#{self.connec_entity_name}, fetching data since #{last_synchronization.updated_at.iso8601}")
      query_param = URI.encode("$filter=updated_at gt '#{last_synchronization.updated_at.iso8601}'")
      response = client.get("/#{self.connec_entity_name.downcase.pluralize}?#{query_param}")
    end
    raise "No data received from Connec! when trying to fetch #{self.connec_entity_name.pluralize}" unless response

    response_hash = JSON.parse(response.body)
    Maestrano::Connector::Rails::ConnectorLogger.log('debug', organization, "received first page entity=#{self.connec_entity_name}, response=#{response.body}")
    if response_hash["#{self.connec_entity_name.downcase.pluralize}"]
      entities << response_hash["#{self.connec_entity_name.downcase.pluralize}"]
    else
      raise "Received unrecognized Connec! data when trying to fetch #{self.connec_entity_name.pluralize}"
    end

    # Fetch subsequent pages
    while response_hash['pagination'] && response_hash['pagination']['next']
      # ugly way to convert https://api-connec/api/v2/group_id/organizations?next_page_params to /organizations?next_page_params
      next_page = response_hash['pagination']['next'].gsub(/^(.*)\/#{self.connec_entity_name.downcase.pluralize}/, self.connec_entity_name.downcase.pluralize)
      response = client.get(next_page)

      raise "No data received from Connec! when trying to fetch subsequent page of #{self.connec_entity_name.pluralize}" unless response
      Maestrano::Connector::Rails::ConnectorLogger.log('debug', organization, "received next page entity=#{self.connec_entity_name}, response=#{response.body}")

      response_hash = JSON.parse(response.body)
      if response_hash["#{self.connec_entity_name.downcase.pluralize}"]
        entities << response_hash["#{self.connec_entity_name.downcase.pluralize}"]
      else
        raise "Received unrecognized Connec! data when trying to fetch subsequent page of #{self.connec_entity_name.pluralize}"
      end
    end

    entities = entities.flatten
    Maestrano::Connector::Rails::ConnectorLogger.log('info', organization, "Received data: Source=Connec!, Entity=#{self.connec_entity_name}, Data=#{entities}")
    entities
  end

  def push_entities_to_connec(connec_client, mapped_external_entities_with_idmaps, organization)
    self.push_entities_to_connec_to(connec_client, mapped_external_entities_with_idmaps, self.connec_entity_name, organization)
  end

  def push_entities_to_connec_to(connec_client, mapped_external_entities_with_idmaps, connec_entity_name, organization)
    Maestrano::Connector::Rails::ConnectorLogger.log('info', organization, "Sending #{@@external_name} #{self.external_entity_name.pluralize} to Connec! #{connec_entity_name.pluralize}")
    mapped_external_entities_with_idmaps.each do |mapped_external_entity_with_idmap|
      external_entity = mapped_external_entity_with_idmap[:entity]
      idmap = mapped_external_entity_with_idmap[:idmap]

      if idmap.connec_id.blank?
        connec_entity = self.create_connec_entity(connec_client, external_entity, connec_entity_name, organization)
        idmap.update_attributes(connec_id: connec_entity['id'], connec_entity: connec_entity_name.downcase, last_push_to_connec: Time.now, message: nil)
      else
        connec_entity = self.update_connec_entity(connec_client, external_entity, idmap.connec_id, connec_entity_name, organization)
        idmap.update_attributes(last_push_to_connec: Time.now, message: nil)
      end

      # Store Connec! error if any
      idmap.update_attributes(message: connec_entity['errors'].first['title']) unless connec_entity.blank? || connec_entity['errors'].blank?
    end
  end

  def create_connec_entity(connec_client, mapped_external_entity, connec_entity_name, organization)
    Maestrano::Connector::Rails::ConnectorLogger.log('info', organization, "Sending create #{connec_entity_name}: #{mapped_external_entity} to Connec!")
    response = connec_client.post("/#{connec_entity_name.downcase.pluralize}", { "#{connec_entity_name.downcase.pluralize}".to_sym => mapped_external_entity })
    raise "No response received from Connec! when trying to create a #{self.connec_entity_name}" unless response
    JSON.parse(response.body)["#{connec_entity_name.downcase.pluralize}"]
  end

  def update_connec_entity(connec_client, mapped_external_entity, connec_id, connec_entity_name, organization)
    Maestrano::Connector::Rails::ConnectorLogger.log('info', organization, "Sending update #{connec_entity_name}: #{mapped_external_entity} to Connec!")
    response = connec_client.put("/#{connec_entity_name.downcase.pluralize}/#{connec_id}", { "#{connec_entity_name.downcase.pluralize}".to_sym => mapped_external_entity })
    raise "No response received from Connec! when trying to update a #{self.connec_entity_name}" unless response
    JSON.parse(response.body)["#{connec_entity_name.downcase.pluralize}"]
  end

  def map_to_external_with_idmap(entity, organization)
    idmap = Maestrano::Connector::Rails::IdMap.find_by(connec_id: entity['id'], connec_entity: self.connec_entity_name.downcase, organization_id: organization.id)

    if idmap && ((!idmap.to_external) || (idmap.last_push_to_external && idmap.last_push_to_external > entity['updated_at']))
      Maestrano::Connector::Rails::ConnectorLogger.log('info', organization, "Discard Connec! #{self.connec_entity_name} : #{entity}")
      nil
    else
      {entity: self.map_to_external(entity, organization), idmap: idmap || Maestrano::Connector::Rails::IdMap.create(connec_id: entity['id'], connec_entity: self.connec_entity_name.downcase, organization_id: organization.id)}
    end
  end

  # ----------------------------------------------
  #                 External methods
  # ----------------------------------------------
  def get_external_entities(client, last_synchronization, organization, opts={})
    Maestrano::Connector::Rails::ConnectorLogger.log('info', organization, "Fetching #{@@external_name} #{self.external_entity_name.pluralize}")
    raise "Not implemented"
  end

  def push_entities_to_external(external_client, mapped_connec_entities_with_idmaps, organization)
    push_entities_to_external_to(external_client, mapped_connec_entities_with_idmaps, self.external_entity_name, organization)
  end

  def push_entities_to_external_to(external_client, mapped_connec_entities_with_idmaps, external_entity_name, organization)
    Maestrano::Connector::Rails::ConnectorLogger.log('info', organization, "Sending Connec! #{self.connec_entity_name.pluralize} to #{@@external_name} #{external_entity_name.pluralize}")
    mapped_connec_entities_with_idmaps.each do |mapped_connec_entity_with_idmap|
      self.push_entity_to_external(external_client, mapped_connec_entity_with_idmap, external_entity_name, organization)
    end
  end

  def push_entity_to_external(external_client, mapped_connec_entity_with_idmap, external_entity_name, organization)
    idmap = mapped_connec_entity_with_idmap[:idmap]
    connec_entity = mapped_connec_entity_with_idmap[:entity]

    begin
      if idmap.external_id.blank?
        external_id = self.create_external_entity(external_client, connec_entity, external_entity_name, organization)
        idmap.update_attributes(external_id: external_id, external_entity: external_entity_name.downcase, last_push_to_external: Time.now, message: nil)
      else
        self.update_external_entity(external_client, connec_entity, idmap.external_id, external_entity_name, organization)
        idmap.update_attributes(last_push_to_external: Time.now, message: nil)
      end
    rescue => e
      # Store External error
      idmap.update_attributes(message: e.message)
    end
  end

  def create_external_entity(client, mapped_connec_entity, external_entity_name, organization)
    Maestrano::Connector::Rails::ConnectorLogger.log('info', organization, "Sending create #{external_entity_name}: #{mapped_connec_entity} to #{@@external_name}")
    raise "Not implemented"
  end

  def update_external_entity(client, mapped_connec_entity, external_id, external_entity_name, organization)
    Maestrano::Connector::Rails::ConnectorLogger.log('info', organization, "Sending update #{external_entity_name} (id=#{external_id}): #{mapped_connec_entity} to #{@@external_name}")
    raise "Not implemented"
  end

  def get_id_from_external_entity_hash(entity)
    raise "Not implemented"
  end

  def get_last_update_date_from_external_entity_hash(entity)
    raise "Not implemented"
  end

  # ----------------------------------------------
  #                 General methods
  # ----------------------------------------------
  # * Discards entities that do not need to be pushed because they have not been updated since their last push
  # * Discards entities from one of the two source in case of conflict
  # * Maps not discarded entities and associates them with their idmap, or create one if there isn't any
  def consolidate_and_map_data(connec_entities, external_entities, organization, opts={})
    external_entities.map!{|entity|
      idmap = Maestrano::Connector::Rails::IdMap.find_by(external_id: self.get_id_from_external_entity_hash(entity), external_entity: self.external_entity_name.downcase, organization_id: organization.id)

      # No idmap: creating one, nothing else to do
      unless idmap
        next {entity: self.map_to_connec(entity, organization), idmap: Maestrano::Connector::Rails::IdMap.create(external_id: self.get_id_from_external_entity_hash(entity), external_entity: self.external_entity_name.downcase, organization_id: organization.id)}
      end

      # Not pushing entity to Connec!
      next nil unless idmap.to_connec

      # Entity has not been modified since its last push to connec!
      if idmap.last_push_to_connec && idmap.last_push_to_connec > self.get_last_update_date_from_external_entity_hash(entity)
        Maestrano::Connector::Rails::ConnectorLogger.log('info', organization, "Discard #{@@external_name} #{self.external_entity_name} : #{entity}")
        next nil
      end

      # Check for conflict with entities from connec!
      if idmap.connec_id && connec_entity = connec_entities.detect{|connec_entity| connec_entity['id'] == idmap.connec_id}
        # We keep the most recently updated entity
        if !opts[:connec_preemption].nil?
          keep_external = !opts[:connec_preemption]
        else
          keep_external = connec_entity['updated_at'] < self.get_last_update_date_from_external_entity_hash(entity)
        end

        if keep_external
          Maestrano::Connector::Rails::ConnectorLogger.log('info', organization, "Conflict between #{@@external_name} #{self.external_entity_name} #{entity} and Connec! #{self.connec_entity_name} #{connec_entity}. Entity from #{@@external_name} kept")
          connec_entities.delete(connec_entity)
          {entity: self.map_to_connec(entity, organization), idmap: idmap}
        else
          Maestrano::Connector::Rails::ConnectorLogger.log('info', organization, "Conflict between #{@@external_name} #{self.external_entity_name} #{entity} and Connec! #{self.connec_entity_name} #{connec_entity}. Entity from Connec! kept")
          nil
        end

      else
        {entity: self.map_to_connec(entity, organization), idmap: idmap}
      end
    }.compact!

    connec_entities.map!{|entity|
      self.map_to_external_with_idmap(entity, organization)
    }.compact!
  end


  # ----------------------------------------------
  #             Entity specific methods
  # Those methods need to be define in each entity
  # ----------------------------------------------
  
  # Entity name in Connec!
  def connec_entity_name
    raise "Not implemented"
  end

  # Entity name in external system
  def external_entity_name
    raise "Not implemented"
  end

  # Entity Mapper Class
  def mapper_class
    raise "Not implemented"
  end
end