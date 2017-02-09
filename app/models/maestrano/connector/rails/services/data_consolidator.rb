module Maestrano::Connector::Rails::Services
  class DataConsolidator
    def initialize(organization, entity_self, options)
      @is_a_subentity = entity_self.is_a?(Maestrano::Connector::Rails::Concerns::SubEntityBase)
      @organization = organization
      @current_entity = entity_self
      @opts = options
    end

    def consolidate_singleton(connec_entities, external_entities)
      return {connec_entities: [], external_entities: []} if external_entities.empty? && connec_entities.empty?

      idmap = @current_entity.class.find_or_create_idmap(organization_id: @organization.id)
      # No to_connec, to_external and inactive consideration here as we don't expect those workflow for singleton

      external_id = @current_entity.class.id_from_external_entity_hash(external_entities.first) if external_entities.first
      # A singleton will be either valid (updated/created) in the external app or in Connec!
      # if keep_external is true we are keeping the external entity
      keep_external = if external_entities.empty?
                        false
                      elsif connec_entities.empty?
                        true
                      elsif @opts.key?(:connec_preemption)
                        !@opts[:connec_preemption]
                      else
                        !connec_more_recent?(connec_entities.first, external_entities.first)
                      end

      if keep_external
        idmap.update(external_id: external_id, name: @current_entity.class.object_name_from_external_entity_hash(external_entities.first))
        return {connec_entities: [], external_entities: [{entity: @current_entity.map_to_connec(external_entities.first), idmap: idmap}]}
      else
        unfold_hash = Maestrano::Connector::Rails::ConnecHelper.unfold_references(connec_entities.first, @current_entity.class.references, @organization)
        entity = unfold_hash[:entity]
        idmap.update(name: @current_entity.class.object_name_from_connec_entity_hash(entity), connec_id: unfold_hash[:connec_id])
        idmap.update(external_id: @current_entity.class.id_from_external_entity_hash(external_entities.first)) unless external_entities.empty?
        return {connec_entities: [{entity: @current_entity.map_to_external(entity), idmap: idmap, id_refs_only_connec_entity: {}}], external_entities: []}
      end
    end

    def consolidate_connec_entities(connec_entities, external_entities, references, external_entity_name)
      connec_entities.map do |entity|
        # Entity has been created before date filtering limit
        next if before_date_filtering_limit?(entity, false) && !@opts[:full_sync]

        # Unfold the id arrays
        # From that point on, the connec_entity contains only string of external ids
        unfold_hash = Maestrano::Connector::Rails::ConnecHelper.unfold_references(entity, references, @organization)
        entity = unfold_hash[:entity]
        next unless entity # discard if at least one record reference is missing
        connec_id = unfold_hash[:connec_id]
        id_refs_only_connec_entity = unfold_hash[:id_refs_only_connec_entity]

        if entity['id'].blank?
          # Expecting find_or_create to be mostly a create
          idmap = @current_entity.class.find_or_create_idmap(organization_id: @organization.id, name: @current_entity.class.object_name_from_connec_entity_hash(entity), external_entity: external_entity_name.downcase, connec_id: connec_id)
          next map_connec_entity_with_idmap(entity, external_entity_name, idmap, id_refs_only_connec_entity)
        end

        # Expecting find_or_create to be mostly a find
        idmap = @current_entity.class.find_or_create_idmap(external_id: entity['id'], organization_id: @organization.id, external_entity: external_entity_name.downcase, connec_id: connec_id)
        idmap.update(name: @current_entity.class.object_name_from_connec_entity_hash(entity))

        next if idmap.external_inactive || !idmap.to_external || (!@opts[:full_sync] && not_modified_since_last_push_to_external?(idmap, entity))

        # Check for conflict with entities from external
        solve_conflict(entity, external_entities, external_entity_name, idmap, id_refs_only_connec_entity)
      end.compact
    end

    def consolidate_external_entities(external_entities, connec_entity_name)
      external_entities.map do |entity|
        # Entity has been created before date filtering limit
        next if before_date_filtering_limit?(entity) && !@opts[:full_sync]

        entity_id = @current_entity.class.id_from_external_entity_hash(entity)
        idmap = @current_entity.class.find_or_create_idmap(external_id: entity_id, organization_id: @organization.id, connec_entity: connec_entity_name.downcase)

        # Not pushing entity to Connec!
        next unless idmap.to_connec

        # Not pushing to Connec! and flagging as inactive if inactive in external application
        inactive = @current_entity.class.inactive_from_external_entity_hash?(entity)
        idmap.update(external_inactive: inactive, name: @current_entity.class.object_name_from_external_entity_hash(entity))
        next if inactive

        # Entity has not been modified since its last push to connec!
        next if !@opts[:full_sync] && not_modified_since_last_push_to_connec?(idmap, entity)

        map_external_entity_with_idmap(entity, connec_entity_name, idmap)
      end.compact
    end

    def before_date_filtering_limit?(entity, external = true)
      @organization.date_filtering_limit && @organization.date_filtering_limit > (external ? @current_entity.class.creation_date_from_external_entity_hash(entity) : entity['created_at'])
    end

    def not_modified_since_last_push_to_connec?(idmap, entity)
      not_modified = idmap.last_push_to_connec && idmap.last_push_to_connec > @current_entity.class.last_update_date_from_external_entity_hash(entity)
      Maestrano::Connector::Rails::ConnectorLogger.log('info', @organization, "Discard #{Maestrano::Connector::Rails::External.external_name} #{@current_entity.class.external_entity_name} : #{entity}") if not_modified
      not_modified
    end

    def not_modified_since_last_push_to_external?(idmap, entity)
      not_modified = idmap.last_push_to_external && idmap.last_push_to_external > entity['updated_at']
      Maestrano::Connector::Rails::ConnectorLogger.log('info', @organization, "Discard Connec! #{@current_entity.class.connec_entity_name} : #{entity}") if not_modified
      not_modified
    end

    def map_external_entity_with_idmap(external_entity, connec_entity_name, idmap)
      entity = if @is_a_subentity
                 @current_entity.map_to(connec_entity_name, external_entity, idmap.last_push_to_connec.nil?)
               else
                 @current_entity.map_to_connec(external_entity, idmap.last_push_to_connec.nil?)
               end
      {entity: entity, idmap: idmap}
    end

    def map_connec_entity_with_idmap(connec_entity, external_entity_name, idmap, id_refs_only_connec_entity)
      entity = if @is_a_subentity
                 @current_entity.map_to(external_entity_name, connec_entity, idmap.last_push_to_external.nil?)
               else
                 @current_entity.map_to_external(connec_entity, idmap.last_push_to_external.nil?)
               end
      {entity: entity, idmap: idmap, id_refs_only_connec_entity: id_refs_only_connec_entity}
    end

    # This methods try to find a external entity among all the external entities matching the connec (mapped) one (same id)
    # If it does not find any, there is no conflict, and it returns the mapped connec entity
    # If it finds one, the conflict is solved either with options or using the entities timestamps
    #   If the connec entity is kept, it is returned mapped and the matching external entity is discarded (deleted from the array)
    #   Else the method returns nil, meaning the connec entity is discarded
    def solve_conflict(connec_entity, external_entities, external_entity_name, idmap, id_refs_only_connec_entity)
      # Here the connec_entity['id'] is an external id (String) because the entity has been unfolded.
      external_entity = external_entities.find { |entity| connec_entity['id'] == @current_entity.class.id_from_external_entity_hash(entity) }
      # No conflict
      return map_connec_entity_with_idmap(connec_entity, external_entity_name, idmap, id_refs_only_connec_entity) unless external_entity

      # Conflict
      # We keep the most recently updated entity
      keep_connec = @opts.key?(:connec_preemption) ? @opts[:connec_preemption] : connec_more_recent?(connec_entity, external_entity)

      if keep_connec
        Maestrano::Connector::Rails::ConnectorLogger.log('info', @organization, "Conflict between #{Maestrano::Connector::Rails::External.external_name} #{external_entity_name} #{external_entity} and Connec! #{@current_entity.class.connec_entity_name} #{connec_entity}. Entity from Connec! kept")
        external_entities.delete(external_entity)
        map_connec_entity_with_idmap(connec_entity, external_entity_name, idmap, id_refs_only_connec_entity)
      else
        Maestrano::Connector::Rails::ConnectorLogger.log('info', @organization, "Conflict between #{Maestrano::Connector::Rails::External.external_name} #{external_entity_name} #{external_entity} and Connec! #{@current_entity.class.connec_entity_name} #{connec_entity}. Entity from external kept")
        nil
      end
    end

    def connec_more_recent?(connec_entity, external_entity)
      connec_entity['updated_at'] > @current_entity.class.last_update_date_from_external_entity_hash(external_entity)
    end
  end
end
