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
  # Used to set a class variable in the mapper in order to
  # have access to the organization for the idmaps queries
  def set_mapper_organization(organization_id)
    self.mapper_class.set_organization(organization_id)
  end

  def unset_mapper_organization
    self.mapper_class.set_organization(nil)
  end

  # Map a Connec! entity to the external format
  def map_to_external(entity)
    self.mapper_class.normalize(entity)
  end

  # Map an external entity to Connec! format
  def map_to_connec(entity)
    self.mapper_class.denormalize(entity)
  end

  # ----------------------------------------------
  #                 Connec! methods
  # ----------------------------------------------
  def get_connec_entities(client, last_synchronization, opts={})
    Rails.logger.info "Fetching Connec! #{self.connec_entity_name}"

    entities = []

    # Fetch first page
    if last_synchronization.blank? || opts[:full_sync]
      response = client.get("/#{self.connec_entity_name.downcase.pluralize}")
    else
      query_param = URI.encode("$filter=updated_at gt '#{last_synchronization.updated_at.iso8601}'")
      response = client.get("/#{self.connec_entity_name.downcase.pluralize}?#{query_param}")
    end
    raise "No data received from Connec! when trying to fetch #{self.connec_entity_name.pluralize}." unless response

    response_hash = JSON.parse(response.body)
    if response_hash["#{self.connec_entity_name.downcase.pluralize}"]
      entities << response_hash["#{self.connec_entity_name.downcase.pluralize}"]
    else
      raise "No data received from Connec! when trying to fetch #{self.connec_entity_name.pluralize}."
    end

    # Fetch subsequent pages
    while response_hash['pagination'] && response_hash['pagination']['next']
      # ugly way to convert https://api-connec/api/v2/group_id/organizations?next_page_params to /organizations?next_page_params
      next_page = response_hash['pagination']['next'].gsub(/^(.*)\/#{self.connec_entity_name.downcase.pluralize}/, entity_name.downcase.pluralize)
      response = client.get(next_page)
      response_hash = JSON.parse(response.body)
      entities << response_hash["#{self.connec_entity_name.downcase.pluralize}"]
    end

    entities = entities.flatten
    Rails.logger.info "Source=Connec!, Entity=#{self.connec_entity_name}, Response=#{entities}"
    entities
  end

  def push_entities_to_connec(connec_client, mapped_external_entities_with_idmaps)
    self.push_entities_to_connec_to(connec_client, mapped_external_entities_with_idmaps, self.connec_entity_name)
  end

  def push_entities_to_connec_to(connec_client, mapped_external_entities_with_idmaps, connec_entity_name)
    Rails.logger.info "Push #{@@external_name} #{self.external_entity_name.pluralize} to Connec! #{connec_entity_name.pluralize}"
    mapped_external_entities_with_idmaps.each do |mapped_external_entity_with_idmap|
      external_entity = mapped_external_entity_with_idmap[:entity]
      idmap = mapped_external_entity_with_idmap[:idmap]

      if idmap.connec_id.blank?
        connec_entity = self.create_entity_to_connec(connec_client, external_entity, connec_entity_name)
        idmap.update_attributes(connec_id: connec_entity['id'], connec_entity: connec_entity_name.downcase, last_push_to_connec: Time.now)
      else
        connec_entity = self.update_entity_to_connec(connec_client, external_entity, idmap.connec_id, connec_entity_name)
        idmap.update_attributes(last_push_to_connec: Time.now)
      end
    end
  end

  def create_entity_to_connec(connec_client, mapped_external_entity, connec_entity_name)
    Rails.logger.info "Create #{connec_entity_name}: #{mapped_external_entity} to Connec!"
    response = connec_client.post("/#{connec_entity_name.downcase.pluralize}", { "#{connec_entity_name.downcase.pluralize}".to_sym => mapped_external_entity })
    JSON.parse(response.body)["#{connec_entity_name.downcase.pluralize}"]
  end

  def update_entity_to_connec(connec_client, mapped_external_entity, connec_id, connec_entity_name)
    Rails.logger.info "Update #{connec_entity_name}: #{mapped_external_entity} to Connec!"
    connec_client.put("/#{connec_entity_name.downcase.pluralize}/#{connec_id}", { "#{connec_entity_name.downcase.pluralize}".to_sym => mapped_external_entity })
  end

  def map_to_external_with_idmap(entity, organization)
    idmap = Maestrano::Connector::Rails::IdMap.find_by(connec_id: entity['id'], connec_entity: self.connec_entity_name.downcase, organization_id: organization.id)

    if idmap && idmap.last_push_to_external && idmap.last_push_to_external > entity['updated_at']
      Rails.logger.info "Discard Connec! #{self.connec_entity_name} : #{entity}"
      nil
    else
      {entity: self.map_to_external(entity), idmap: idmap || Maestrano::Connector::Rails::IdMap.create(connec_id: entity['id'], connec_entity: self.connec_entity_name.downcase, organization_id: organization.id)}
    end
  end

  # ----------------------------------------------
  #                 External methods
  # ----------------------------------------------
  def get_external_entities(client, last_synchronization, opts={})
    Rails.logger.info "Fetching #{@@external_name} #{self.external_entity_name.pluralize}"
    raise "Not implemented"
  end

  def push_entities_to_external(external_client, mapped_connec_entities_with_idmaps)
    push_entities_to_external_to(external_client, mapped_connec_entities_with_idmaps, self.external_entity_name)
  end

  def push_entities_to_external_to(external_client, mapped_connec_entities_with_idmaps, external_entity_name)
    Rails.logger.info "Push Connec! #{self.connec_entity_name.pluralize} to #{@@external_name} #{external_entity_name.pluralize}"
    mapped_connec_entities_with_idmaps.each do |mapped_connec_entity_with_idmap|
      self.push_entity_to_external(external_client, mapped_connec_entity_with_idmap, external_entity_name)
    end
  end

  def push_entity_to_external(external_client, mapped_connec_entity_with_idmap, external_entity_name)
    idmap = mapped_connec_entity_with_idmap[:idmap]
    connec_entity = mapped_connec_entity_with_idmap[:entity]

    if idmap.external_id.blank?
      external_id = self.create_entity_to_external(external_client, connec_entity, external_entity_name)
      idmap.update_attributes(external_id: external_id, external_entity: external_entity_name.downcase, last_push_to_external: Time.now)
    else
      self.update_entity_to_external(external_client, connec_entity, idmap.external_id, external_entity_name)
      idmap.update_attributes(last_push_to_external: Time.now)
    end
  end

  def create_entity_to_external(client, mapped_connec_entity, external_entity_name)
    Rails.logger.info "Create #{external_entity_name}: #{mapped_connec_entity} to #{@@external_name}"
    raise "Not implemented"
  end

  def update_entity_to_external(client, mapped_connec_entity, external_id, external_entity_name)
    Rails.logger.info "Update #{external_entity_name} (id=#{external_id}): #{mapped_connec_entity} to #{@@external_name}"
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
  def consolidate_and_map_data(connec_entities, external_entities, organization, opts)
    external_entities.map!{|entity|
      idmap = Maestrano::Connector::Rails::IdMap.find_by(external_id: self.get_id_from_external_entity_hash(entity), external_entity: self.external_entity_name.downcase, organization_id: organization.id)

      # No idmap: creating one, nothing else to do
      unless idmap
        next {entity: self.map_to_connec(entity), idmap: Maestrano::Connector::Rails::IdMap.create(external_id: self.get_id_from_external_entity_hash(entity), external_entity: self.external_entity_name.downcase, organization_id: organization.id)}
      end

      # Entity has not been modified since its last push to connec!
      if idmap.last_push_to_connec && idmap.last_push_to_connec > self.get_last_update_date_from_external_entity_hash(entity)
        Rails.logger.info "Discard #{@@external_name} #{self.external_entity_name} : #{entity}"
        next nil
      end

      # Check for conflict with entities from connec!
      if idmap.connec_id && connec_entity = connec_entities.detect{|connec_entity| connec_entity['id'] == idmap.connec_id}
        # We keep the most recently updated entity
        if !opts[:connec_preemption] || connec_entity['updated_at'] < self.get_last_update_date_from_external_entity_hash(entity)
          Rails.logger.info "Conflict between #{@@external_name} #{self.external_entity_name} #{entity} and Connec! #{self.connec_entity_name} #{connec_entity}. Entity from #{@@external_name} kept"
          connec_entities.delete(connec_entity)
          {entity: self.map_to_connec(entity), idmap: idmap}
        else
          Rails.logger.info "Conflict between #{@@external_name} #{self.external_entity_name} #{entity} and Connec! #{self.connec_entity_name} #{connec_entity}. Entity from Connec! kept"
          nil
        end

      else
        {entity: self.map_to_connec(entity), idmap: idmap}
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
  def connec_entity_name
    raise "Not implemented"
  end

  def external_entity_name
    raise "Not implemented"
  end

  def mapper_class
    raise "Not implemented"
  end
end