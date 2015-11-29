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
    self.mapper_name.constantize.set_organization(organization_id)
  end

  def unset_mapper_organization
    self.mapper_name.constantize.set_organization(nil)
  end

  # Map a Connec! entity to the external format
  def map_to_external(entity)
    self.mapper_name.constantize.normalize(entity)
  end

  # Map an external entity to Connec! format
  def map_to_connec(entity)
    self.mapper_name.constantize.denormalize(entity)
  end

  # ----------------------------------------------
  #                 Connec! methods
  # ----------------------------------------------
  def get_connec_entities(client, last_synchronization, opts={})
    Rails.logger.info "Fetching Connec! #{self.connec_entity_name.pluralize}"

    entities = []

    # Fetch first page
    if last_synchronization.blank? || opts[:full_sync]
      response = client.get("/#{self.connec_entity_name.downcase.pluralize}")
    else
      query_param = URI.encode("$filter=updated_at gt '#{last_synchronization.updated_at.strftime('%F')}'")
      response = client.get("/#{self.connec_entity_name.downcase.pluralize}?#{query_param}")
    end

    response_hash = JSON.parse(response.body)
    if response_hash["#{self.connec_entity_name.downcase.pluralize}"]
      entities << response_hash["#{self.connec_entity_name.downcase.pluralize}"]
    else
      raise "No data received from Connec! when trying to fetch #{self.connec_entity_name.pluralize}."
    end

    # Fetch subsequent pages
    while response_hash['pagination'] && response_hash['pagination']['next']
      # ugly way to convert https://api-connec/api/v2/group_id/organizations?next_page_params to /organizations?next_page_params
      next_page = response_hash['pagination']['next'].gsub(/^(.*)\/#{self.connec_entity_name.downcase.pluralize}/, self.connec_entity_name.downcase.pluralize)
      response = client.get(next_page)
      response_hash = JSON.parse(response.body)
      entities << response_hash["#{self.connec_entity_name.downcase.pluralize}"]
    end

    entities = entities.flatten
    Rails.logger.info "Source=Connec!, Entity=#{self.connec_entity_name}, Response=#{entities}"
    entities
  end

  def push_entities_to_connec(connec_client, mapped_external_entities_with_idmaps)
    Rails.logger.info "Push #{@@external_name} #{self.external_entity_name.pluralize} to Connec! #{self.connec_entity_name.pluralize}"
    mapped_external_entities_with_idmaps.each do |external_entity_with_idmap|
      external_entity = external_entity_with_idmap[:entity]
      idmap = external_entity_with_idmap[:idmap]

      if idmap.connec_id.blank?
        connec_entity = self.create_entity_to_connec(connec_client, external_entity)
        idmap.update_attributes(connec_id: connec_entity['id'], connec_entity: self.connec_entity_name.downcase, last_push_to_connec: Time.now)
      else
        connec_entity = self.update_entity_to_connec(connec_client, external_entity, idmap.connec_id)
        idmap.update_attributes(last_push_to_connec: Time.now)
      end
    end
  end

  def create_entity_to_connec(client, mapped_external_entity)
    Rails.logger.info "Create #{self.connec_entity_name}: #{mapped_external_entity} to Connec!"
    response = client.post("/#{self.connec_entity_name.downcase.pluralize}", { "#{self.connec_entity_name.downcase.pluralize}".to_sym => mapped_external_entity })
    JSON.parse(response.body)["#{self.connec_entity_name.downcase.pluralize}"]
  end

  def update_entity_to_connec(client, mapped_external_entity, connec_id)
    Rails.logger.info "Update #{self.connec_entity_name}: #{mapped_external_entity} to Connec!"
    client.put("/#{self.connec_entity_name.downcase.pluralize}/#{connec_id}", { "#{self.connec_entity_name.downcase.pluralize}".to_sym => mapped_external_entity })
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

  def push_entities_to_external(external_client, connec_entities_with_idmaps)
    Rails.logger.info "Push Connec! #{self.connec_entity_name.pluralize} to #{@@external_name} #{self.external_entity_name.pluralize}"
    connec_entities_with_idmaps.each do |connec_entity_with_idmap|
      push_entity_to_external(external_client, connec_entity_with_idmap)
    end
  end

  def push_entity_to_external(external_client, connec_entity_with_idmap)
    idmap = connec_entity_with_idmap[:idmap]
    connec_entity = connec_entity_with_idmap[:entity]

    if idmap.external_id.blank?
      external_id = self.create_entity_to_external(external_client, connec_entity)
      idmap.update_attributes(external_id: external_id, external_entity: self.external_entity_name, last_push_to_external: Time.now)
    else
      self.update_entity_to_external(external_client, connec_entity, idmap.external_id)
      idmap.update_attributes(last_push_to_external: Time.now)
    end
  end

  def create_entity_to_external(client, mapped_connec_entity)
    Rails.logger.info "Create #{self.external_entity_name}: #{mapped_connec_entity} to #{@@external_name}"
    raise "Not implemented"
  end

  def update_entity_to_external(client, mapped_connec_entity, external_id)
    Rails.logger.info "Update #{self.external_entity_name} (id=#{external_id}): #{mapped_connec_entity} to #{@@external_name}"
    raise "Not implemented"
  end

  # ----------------------------------------------
  #                 General methods
  # ----------------------------------------------
  # * Discards entities that do not need to be pushed because they have not been updated since their last push
  # * Discards entities from one of the two source in case of conflict
  # * Maps not discarded entities and associates them with their idmap, or create one if there isn't any
  def consolidate_and_map_data(connec_entities, external_entities, organization)
    raise "Not implemented"
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

  def mapper_name
    raise "Not implemented"
  end
end