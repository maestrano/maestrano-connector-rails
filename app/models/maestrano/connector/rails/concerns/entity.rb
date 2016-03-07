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
    mapper_class.normalize(entity)
  end

  # Map an external entity to Connec! format
  def map_to_connec(entity, organization)
    mapper_class.denormalize(entity)
  end

  # ----------------------------------------------
  #                 IdMap methods
  # ----------------------------------------------
  def names_hash
    {
      connec_entity: connec_entity_name.downcase,
      external_entity: external_entity_name.downcase
    }
  end

  def find_or_create_idmap(organization_and_id)
    Maestrano::Connector::Rails::IdMap.find_or_create_by(names_hash.merge(organization_and_id))
  end

  # organization_and_id can be either:
  # * {connec_id: 'id', organization_id: 'id'}
  # * {external_id: 'id', organization_id: 'id'}
  # Needs to include either connec_entity or external_entity for complex entities
  def find_idmap(organization_and_id)
    Maestrano::Connector::Rails::IdMap.find_by(names_hash.merge(organization_and_id))
  end

  def create_idmap_from_external_entity(entity, organization)
    h = names_hash.merge({
      external_id: get_id_from_external_entity_hash(entity),
      name: object_name_from_external_entity_hash(entity),
      organization_id: organization.id
    })
    Maestrano::Connector::Rails::IdMap.create(h)
  end

  def create_idmap_from_connec_entity(entity, organization)
    h = names_hash.merge({
      connec_id: entity['id'],
      name: object_name_from_connec_entity_hash(entity),
      organization_id: organization.id
    })
    Maestrano::Connector::Rails::IdMap.create(h)
  end
  # ----------------------------------------------
  #                 Connec! methods
  # ----------------------------------------------
  def normalized_connec_entity_name
    if singleton?
      connec_entity_name.downcase
    else
      connec_entity_name.downcase.pluralize
    end
  end

  def get_connec_entities(client, last_synchronization, organization, opts={})
    Maestrano::Connector::Rails::ConnectorLogger.log('info', organization, "Fetching Connec! #{connec_entity_name}")

    entities = []

    # Fetch first page
    if last_synchronization.blank? || opts[:full_sync]
      Maestrano::Connector::Rails::ConnectorLogger.log('debug', organization, "entity=#{connec_entity_name}, fetching all data")
      response = client.get("/#{normalized_connec_entity_name}")
    else
      Maestrano::Connector::Rails::ConnectorLogger.log('debug', organization, "entity=#{connec_entity_name}, fetching data since #{last_synchronization.updated_at.iso8601}")
      query_param = URI.encode("$filter=updated_at gt '#{last_synchronization.updated_at.iso8601}'")
      response = client.get("/#{normalized_connec_entity_name}?#{query_param}")
    end
    raise "No data received from Connec! when trying to fetch #{connec_entity_name.pluralize}" unless response

    response_hash = JSON.parse(response.body)
    Maestrano::Connector::Rails::ConnectorLogger.log('debug', organization, "received first page entity=#{connec_entity_name}, response=#{response.body}")
    if response_hash["#{normalized_connec_entity_name}"]
      entities << response_hash["#{normalized_connec_entity_name}"]
    else
      raise "Received unrecognized Connec! data when trying to fetch #{connec_entity_name.pluralize}"
    end

    # Fetch subsequent pages
    while response_hash['pagination'] && response_hash['pagination']['next']
      # ugly way to convert https://api-connec/api/v2/group_id/organizations?next_page_params to /organizations?next_page_params
      next_page = response_hash['pagination']['next'].gsub(/^(.*)\/#{normalized_connec_entity_name}/, normalized_connec_entity_name)
      response = client.get(next_page)

      raise "No data received from Connec! when trying to fetch subsequent page of #{connec_entity_name.pluralize}" unless response
      Maestrano::Connector::Rails::ConnectorLogger.log('debug', organization, "received next page entity=#{connec_entity_name}, response=#{response.body}")

      response_hash = JSON.parse(response.body)
      if response_hash["#{normalized_connec_entity_name}"]
        entities << response_hash["#{normalized_connec_entity_name}"]
      else
        raise "Received unrecognized Connec! data when trying to fetch subsequent page of #{connec_entity_name.pluralize}"
      end
    end

    entities = entities.flatten
    Maestrano::Connector::Rails::ConnectorLogger.log('info', organization, "Received data: Source=Connec!, Entity=#{connec_entity_name}, Data=#{entities}")
    entities
  end

  def push_entities_to_connec(connec_client, mapped_external_entities_with_idmaps, organization)
    push_entities_to_connec_to(connec_client, mapped_external_entities_with_idmaps, connec_entity_name, organization)
  end

  def push_entities_to_connec_to(connec_client, mapped_external_entities_with_idmaps, connec_entity_name, organization)
    Maestrano::Connector::Rails::ConnectorLogger.log('info', organization, "Sending #{@@external_name} #{external_entity_name.pluralize} to Connec! #{connec_entity_name.pluralize}")
    mapped_external_entities_with_idmaps.each do |mapped_external_entity_with_idmap|
      external_entity = mapped_external_entity_with_idmap[:entity]
      idmap = mapped_external_entity_with_idmap[:idmap]

      begin
        if idmap.connec_id.blank?
          connec_entity = create_connec_entity(connec_client, external_entity, connec_entity_name, organization)
          idmap.update_attributes(connec_id: connec_entity['id'], connec_entity: connec_entity_name.downcase, last_push_to_connec: Time.now, message: nil)
        else
          connec_entity = update_connec_entity(connec_client, external_entity, idmap.connec_id, connec_entity_name, organization)
          idmap.update_attributes(last_push_to_connec: Time.now, message: nil)
        end
      rescue => e
        # Store Connec! error if any
        idmap.update_attributes(message: e.message)
      end
    end
  end

  def create_connec_entity(connec_client, mapped_external_entity, connec_entity_name, organization)
    Maestrano::Connector::Rails::ConnectorLogger.log('info', organization, "Sending create #{connec_entity_name}: #{mapped_external_entity} to Connec!")
    response = connec_client.post("/#{normalized_connec_entity_name}", { "#{normalized_connec_entity_name}".to_sym => mapped_external_entity })
    response = JSON.parse(response.body)
    raise "Connec!: #{response['errors']['title']}" if response['errors'] && response['errors']['title']
    response["#{normalized_connec_entity_name}"]
  end

  def update_connec_entity(connec_client, mapped_external_entity, connec_id, connec_entity_name, organization)
    Maestrano::Connector::Rails::ConnectorLogger.log('info', organization, "Sending update #{connec_entity_name}: #{mapped_external_entity} to Connec!")
    response = connec_client.put("/#{normalized_connec_entity_name}/#{connec_id}", { "#{normalized_connec_entity_name}".to_sym => mapped_external_entity })
    response = JSON.parse(response.body)
    raise "Connec!: #{response['errors']['title']}" if response['errors'] && response['errors']['title']
    response["#{normalized_connec_entity_name}"]
  end

  def map_to_external_with_idmap(entity, organization)
    idmap = find_idmap({connec_id: entity['id'], organization_id: organization.id})

    if idmap && ((!idmap.to_external) || (idmap.last_push_to_external && idmap.last_push_to_external > entity['updated_at']))
      Maestrano::Connector::Rails::ConnectorLogger.log('info', organization, "Discard Connec! #{connec_entity_name} : #{entity}")
      nil
    else
      {entity: map_to_external(entity, organization), idmap: idmap || create_idmap_from_connec_entity(entity, organization)}
    end
  end

  # ----------------------------------------------
  #                 External methods
  # ----------------------------------------------
  def get_external_entities(client, last_synchronization, organization, opts={})
    Maestrano::Connector::Rails::ConnectorLogger.log('info', organization, "Fetching #{@@external_name} #{external_entity_name.pluralize}")
    raise "Not implemented"
  end

  def push_entities_to_external(external_client, mapped_connec_entities_with_idmaps, organization)
    push_entities_to_external_to(external_client, mapped_connec_entities_with_idmaps, external_entity_name, organization)
  end

  def push_entities_to_external_to(external_client, mapped_connec_entities_with_idmaps, external_entity_name, organization)
    Maestrano::Connector::Rails::ConnectorLogger.log('info', organization, "Sending Connec! #{connec_entity_name.pluralize} to #{@@external_name} #{external_entity_name.pluralize}")
    mapped_connec_entities_with_idmaps.each do |mapped_connec_entity_with_idmap|
      push_entity_to_external(external_client, mapped_connec_entity_with_idmap, external_entity_name, organization)
    end
  end

  def push_entity_to_external(external_client, mapped_connec_entity_with_idmap, external_entity_name, organization)
    idmap = mapped_connec_entity_with_idmap[:idmap]
    connec_entity = mapped_connec_entity_with_idmap[:entity]

    begin
      if idmap.external_id.blank?
        external_id = create_external_entity(external_client, connec_entity, external_entity_name, organization)
        idmap.update_attributes(external_id: external_id, external_entity: external_entity_name.downcase, last_push_to_external: Time.now, message: nil)
      else
        update_external_entity(external_client, connec_entity, idmap.external_id, external_entity_name, organization)
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
  # * Return a hash {connec_entities: [], external_entities: []}
  def consolidate_and_map_data(connec_entities, external_entities, organization, opts={})
    return consolidate_and_map_singleton(connec_entities, external_entities, organization, opts) if singleton?

    mapped_external_entities = external_entities.map{|entity|
      idmap = find_idmap({external_id: get_id_from_external_entity_hash(entity), organization_id: organization.id})
      # No idmap: creating one, nothing else to do
      unless idmap
        next {entity: map_to_connec(entity, organization), idmap: create_idmap_from_external_entity(entity, organization)}
      end

      # Not pushing entity to Connec!
      next nil unless idmap.to_connec

      # Entity has not been modified since its last push to connec!
      next nil if self.class.not_modified_since_last_push_to_connec(idmap, entity, self, organization)

      # Check for conflict with entities from connec!
      self.class.solve_conflict(entity, self, connec_entities, connec_entity_name, idmap, organization, opts)
    }
    mapped_external_entities.compact!

    mapped_connec_entities = connec_entities.map{|entity|
      map_to_external_with_idmap(entity, organization)
    }
    mapped_connec_entities.compact!

    return {connec_entities: mapped_connec_entities, external_entities: mapped_external_entities}
  end

  def consolidate_and_map_singleton(connec_entities, external_entities, organization, opts={})
    return {connec_entities: [], external_entities: []} if external_entities.empty? && connec_entities.empty?

    idmap = find_or_create_idmap({organization_id: organization.id})

    if external_entities.empty?
      keep_external = false
    elsif connec_entities.empty?
      keep_external = true
    elsif !opts[:connec_preemption].nil?
      keep_external = !opts[:connec_preemption]
    else
      keep_external = self.class.is_external_more_recent?(connec_entities.first, external_entities.first, self)
    end
    if keep_external
      idmap.update(external_id: get_id_from_external_entity_hash(external_entities.first))
      return {connec_entities: [], external_entities: [{entity: map_to_connec(external_entities.first, organization), idmap: idmap}]}
    else
      idmap.update(connec_id: connec_entities.first['id'])
      return {connec_entities: [{entity: map_to_external(connec_entities.first, organization), idmap: idmap}], external_entities: []}
    end
  end

  # ----------------------------------------------
  #             Entity specific methods
  # Those methods need to be define in each entity
  # ----------------------------------------------
  # Is this resource a singleton (in Connec!)?
  def singleton?
    false
  end

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

  # Return a string representing the object from a connec! entity hash
  def object_name_from_connec_entity_hash(entity)
    raise "Not implemented"
  end

  # Return a string representing the object from an external entity hash
  def object_name_from_external_entity_hash(entity)
    raise "Not implemented"
  end


  # ----------------------------------------------
  #             Internal helper methods
  # ----------------------------------------------
  module ClassMethods
    def not_modified_since_last_push_to_connec(idmap, entity, entity_instance, organization)
      result = idmap.last_push_to_connec && idmap.last_push_to_connec > entity_instance.get_last_update_date_from_external_entity_hash(entity)
      Maestrano::Connector::Rails::ConnectorLogger.log('info', organization, "Discard #{entity_instance.external_entity_name} : #{entity}") unless result
      result
    end

    def is_external_more_recent?(connec_entity, external_entity, entity_instance)
      connec_entity['updated_at'] < entity_instance.get_last_update_date_from_external_entity_hash(external_entity)
    end

    def solve_conflict(external_entity, entity_instance, connec_entities, connec_entity_name, idmap, organization, opts)
      if idmap.connec_id && connec_entity = connec_entities.detect{|connec_entity| connec_entity['id'] == idmap.connec_id}
        # We keep the most recently updated entity
        if !opts[:connec_preemption].nil?
          keep_external = !opts[:connec_preemption]
        else
          keep_external = is_external_more_recent?(connec_entity, external_entity, entity_instance)
        end

        if keep_external
          Maestrano::Connector::Rails::ConnectorLogger.log('info', organization, "Conflict between #{entity_instance.external_entity_name} #{external_entity} and Connec! #{connec_entity_name} #{connec_entity}. Entity from external kept")
          connec_entities.delete(connec_entity)
          entity_instance.map_external_entity_with_idmap(external_entity, connec_entity_name, idmap, organization)
        else
          Maestrano::Connector::Rails::ConnectorLogger.log('info', organization, "Conflict between #{entity_instance.external_entity_name} #{external_entity} and Connec! #{connec_entity_name} #{connec_entity}. Entity from Connec! kept")
          nil
        end

      else
        entity_instance.map_external_entity_with_idmap(external_entity, connec_entity_name, idmap, organization)
      end
    end
  end

  def map_external_entity_with_idmap(external_entity, connec_entity_name, idmap, organization)
    {entity: map_to_connec(external_entity, organization), idmap: idmap}
  end
end