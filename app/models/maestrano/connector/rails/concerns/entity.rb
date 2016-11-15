module Maestrano::Connector::Rails::Concerns::Entity
  extend ActiveSupport::Concern

  module ClassMethods
    # ----------------------------------------------
    #                 IdMap methods
    # ----------------------------------------------
    # Default names hash used for id maps creation and look up
    def names_hash
      {
        connec_entity: connec_entity_name.downcase,
        external_entity: external_entity_name.downcase
      }
    end

    # organization_and_id can be either:
    # * {connec_id: 'id', organization_id: 'id'}
    # * {external_id: 'id', organization_id: 'id'}
    # Needs to include either connec_entity or external_entity for sub entities
    def find_or_create_idmap(organization_and_id)
      Maestrano::Connector::Rails::IdMap.find_or_create_by(names_hash.merge(organization_and_id))
    end

    def find_idmap(organization_and_id)
      Maestrano::Connector::Rails::IdMap.find_by(names_hash.merge(organization_and_id))
    end

    def create_idmap(organization_and_id)
      Maestrano::Connector::Rails::IdMap.create(names_hash.merge(organization_and_id))
    end

    # ----------------------------------------------
    #              Connec! methods
    # ----------------------------------------------
    def normalized_connec_entity_name
      normalize_connec_entity_name(connec_entity_name)
    end

    def normalize_connec_entity_name(name)
      singleton? ? name.parameterize('_') : name.parameterize('_').pluralize
    end

    # ----------------------------------------------
    #             External methods
    # ----------------------------------------------
    def id_from_external_entity_hash(entity)
      raise 'Not implemented'
    end

    def last_update_date_from_external_entity_hash(entity)
      raise 'Not implemented'
    end

    def creation_date_from_external_entity_hash(entity)
      raise 'Not implemented'
    end

    # Return a string representing the object from a connec! entity hash
    def object_name_from_connec_entity_hash(entity)
      raise 'Not implemented'
    end

    # Return a string representing the object from an external entity hash
    def object_name_from_external_entity_hash(entity)
      raise 'Not implemented'
    end

    # Returns a boolean
    # Returns true is the entity is flagged as inactive (deleted) in the external application
    def inactive_from_external_entity_hash?(entity)
      false
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
      raise 'Not implemented'
    end

    # Entity name in external system
    def external_entity_name
      raise 'Not implemented'
    end

    # Entity Mapper Class
    def mapper_class
      raise 'Not implemented'
    end

    # Optional creation only mapper, defaults to main mapper
    def creation_mapper_class
      mapper_class
    end

    # An array of connec fields that are references
    # Can also be an hash with keys record_references and id_references
    def references
      []
    end

    # An array of fields for smart merging. See Connec! documentation
    def connec_matching_fields
      nil
    end

    def can_read_connec?
      can_write_external?
    end

    def can_read_external?
      can_write_connec?
    end

    def can_update_connec?
      true
    end

    def can_write_connec?
      true
    end

    def can_write_external?
      true
    end

    def can_update_external?
      true
    end

    # ----------------------------------------------
    #                 Helper methods
    # ----------------------------------------------
    # Returns the count and first element of the array
    # Used for batch calling during the first synchronization
    def count_and_first(entities)
      {count: entities.size, first: entities.first}
    end

    # For display purposes only
    def public_connec_entity_name
      singleton? ? connec_entity_name : connec_entity_name.pluralize
    end

    # For display purposes only
    def public_external_entity_name
      external_entity_name.pluralize
    end
  end

  # ==============================================
  # ==============================================
  #                 Instance  methods
  # ==============================================
  # ==============================================

  # ----------------------------------------------
  #                 Mapper methods
  # ----------------------------------------------
  # Map a Connec! entity to the external model
  def map_to_external(entity, first_time_mapped = nil)
    mapper = first_time_mapped ? self.class.creation_mapper_class : self.class.mapper_class
    map_to_external_helper(entity, mapper)
  end

  def map_to_external_helper(entity, mapper)
    # instance_values returns a hash with all the instance variables (http://apidock.com/rails/v4.0.2/Object/instance_values)
    # that includes opts, organization, connec_client, external_client, and all the connector and entity specific variables
    mapper.normalize(entity, instance_values.with_indifferent_access).with_indifferent_access
  end

  # Map an external entity to Connec! model
  def map_to_connec(entity, first_time_mapped = nil)
    mapper = first_time_mapped ? self.class.creation_mapper_class : self.class.mapper_class
    map_to_connec_helper(entity, mapper, self.class.references)
  end

  def map_to_connec_helper(entity, mapper, references)
    mapped_entity = mapper.denormalize(entity, instance_values.with_indifferent_access).merge(id: self.class.id_from_external_entity_hash(entity))
    folded_entity = Maestrano::Connector::Rails::ConnecHelper.fold_references(mapped_entity, references, @organization)
    folded_entity[:opts] = (mapped_entity[:opts] || {}).merge(matching_fields: self.class.connec_matching_fields) if self.class.connec_matching_fields
    folded_entity
  end

  # ----------------------------------------------
  #                 Connec! methods
  # ----------------------------------------------
  # Supported options:
  # * full_sync
  # * $filter (see Connec! documentation)
  # * $orderby (see Connec! documentation)
  # * __skip_connec for half syncs
  # * __limit and __skip for batch calls
  # Returns an array of connec entities
  def get_connec_entities(last_synchronization_date = nil)
    return [] if @opts[:__skip_connec] || !self.class.can_read_connec?

    Maestrano::Connector::Rails::ConnectorLogger.log('info', @organization, "Fetching Connec! #{self.class.connec_entity_name}")

    query_params = {}
    query_params[:$orderby] = @opts[:$orderby] if @opts[:$orderby]

    batched_fetch = @opts[:__limit] && @opts[:__skip]
    if batched_fetch
      query_params[:$top] = @opts[:__limit]
      query_params[:$skip] = @opts[:__skip]
    end

    if last_synchronization_date.blank? || @opts[:full_sync]
      query_params[:$filter] = @opts[:$filter] if @opts[:$filter]
    else
      query_params[:$filter] = "updated_at gt '#{last_synchronization_date.iso8601}'" + (@opts[:$filter] ? " and #{@opts[:$filter]}" : '')
    end

    Maestrano::Connector::Rails::ConnectorLogger.log('debug', @organization, "entity=#{self.class.connec_entity_name}, fetching data with #{query_params.to_query}")
    uri = "#{self.class.normalized_connec_entity_name}?#{query_params.to_query}"
    response_hash = fetch_connec(uri)
    entities = response_hash[self.class.normalized_connec_entity_name]
    entities = [entities] if self.class.singleton?

    # Only the first page if batched_fetch
    unless batched_fetch
      # Fetch subsequent pages
      while response_hash['pagination'] && response_hash['pagination']['next']
        # ugly way to convert https://api-connec/api/v2/group_id/organizations?next_page_params to /organizations?next_page_params
        next_page = response_hash['pagination']['next'].gsub(/^(.*)\/#{self.class.normalized_connec_entity_name}/, self.class.normalized_connec_entity_name)

        response_hash = fetch_connec(next_page)
        entities.concat response_hash[self.class.normalized_connec_entity_name]
      end
    end

    entities.flatten!
    Maestrano::Connector::Rails::ConnectorLogger.log('info', @organization, "Received data: Source=Connec!, Entity=#{self.class.connec_entity_name}, Data=#{entities}")
    entities
  end

  # Wrapper
  # TODO, useless?
  # Can be replace by def push_entities_to_connec_to(mapped_external_entities_with_idmaps, connec_entity_name = self.class.connec_entity_name) ?
  def push_entities_to_connec(mapped_external_entities_with_idmaps)
    push_entities_to_connec_to(mapped_external_entities_with_idmaps, self.class.connec_entity_name)
  end

  # Pushes the external entities to Connec!, and updates the idmaps with either
  # * connec_id and push timestamp
  # * error message
  def push_entities_to_connec_to(mapped_external_entities_with_idmaps, connec_entity_name)
    return unless self.class.can_write_connec?

    Maestrano::Connector::Rails::ConnectorLogger.log('info', @organization, "Sending #{Maestrano::Connector::Rails::External.external_name} #{self.class.external_entity_name.pluralize} to Connec! #{connec_entity_name.pluralize}")

    # As we're doing only POST, we use the idmaps to filter out updates
    unless self.class.can_update_connec?
      mapped_external_entities_with_idmaps.select! { |mapped_external_entity_with_idmap| !mapped_external_entity_with_idmap[:idmap].connec_id }
    end

    proc = ->(mapped_external_entity_with_idmap) { batch_op('post', mapped_external_entity_with_idmap[:entity], nil, self.class.normalize_connec_entity_name(connec_entity_name)) }
    batch_calls(mapped_external_entities_with_idmaps, proc, connec_entity_name)
  end

  # Helper method to build an op for batch call
  # See http://maestrano.github.io/connec/#api-|-batch-calls
  def batch_op(method, mapped_external_entity, id, connec_entity_name)
    Maestrano::Connector::Rails::ConnectorLogger.log('info', @organization, "Sending #{method.upcase} #{connec_entity_name}: #{mapped_external_entity} to Connec! (Preparing batch request)")
    {
      method: method,
      url: "/api/v2/#{@organization.uid}/#{connec_entity_name}/#{id}", # id should be nil for POST
      params: {
        connec_entity_name.to_sym => mapped_external_entity
      }
    }
  end

  # ----------------------------------------------
  #                 External methods
  # ----------------------------------------------
  # Wrapper to process options and limitations
  def get_external_entities_wrapper(last_synchronization_date = nil, entity_name = self.class.external_entity_name)
    return [] if @opts[:__skip_external] || !self.class.can_read_external?
    get_external_entities(entity_name, last_synchronization_date)
  end

  # To be implemented in each connector
  def get_external_entities(external_entity_name, last_synchronization_date = nil)
    Maestrano::Connector::Rails::ConnectorLogger.log('info', @organization, "Fetching #{Maestrano::Connector::Rails::External.external_name} #{external_entity_name.pluralize}")
    raise 'Not implemented'
  end

  # Wrapper
  # TODO, useless?
  # Can be replace by def push_entities_to_external_to(mapped_connec_entities_with_idmaps, external_entity_name = self.class.external_entity_name) ?
  def push_entities_to_external(mapped_connec_entities_with_idmaps)
    push_entities_to_external_to(mapped_connec_entities_with_idmaps, self.class.external_entity_name)
  end

  # Pushes connec entities to the external application
  # Sends new external ids to Connec! (either only the id, or the id + the id references)
  def push_entities_to_external_to(mapped_connec_entities_with_idmaps, external_entity_name)
    return unless self.class.can_write_external?

    Maestrano::Connector::Rails::ConnectorLogger.log('info', @organization, "Sending Connec! #{self.class.connec_entity_name.pluralize} to #{Maestrano::Connector::Rails::External.external_name} #{external_entity_name.pluralize}")

    entities_to_send_to_connec = mapped_connec_entities_with_idmaps.map { |mapped_connec_entity_with_idmap|
      push_entity_to_external(mapped_connec_entity_with_idmap, external_entity_name)
    }.compact

    # Send the external ids to connec if it was a creation
    # or if there are some sub entities ids to send (completed_hash)
    return if entities_to_send_to_connec.empty?

    # Build a batch op from an idmap and a competed hash
    # with either only the id, or the id + id references
    proc = lambda do |entity|
      id = {id: [Maestrano::Connector::Rails::ConnecHelper.id_hash(entity[:idmap].external_id, @organization)]}
      body = entity[:completed_hash]&.merge(id) || id
      batch_op('put', body, entity[:idmap].connec_id, self.class.normalized_connec_entity_name)
    end
    batch_calls(entities_to_send_to_connec, proc, self.class.connec_entity_name, true)
  end

  # Creates or updates connec entity to external
  # Returns nil if there is nothing to send back to Connec!
  # Returns an hash if
  #   - it's a creation: need to send id to Connec! (and potentially id references)
  #   - it's an update but it's the first push of a singleton
  #   - it's an update and there's id references to send to Connec!
  def push_entity_to_external(mapped_connec_entity_with_idmap, external_entity_name)
    idmap = mapped_connec_entity_with_idmap[:idmap]
    mapped_connec_entity = mapped_connec_entity_with_idmap[:entity]
    id_refs_only_connec_entity = mapped_connec_entity_with_idmap[:id_refs_only_connec_entity]

    begin
      # Create and return id to send to connec!
      if idmap.external_id.blank?
        external_hash = create_external_entity(mapped_connec_entity, external_entity_name)
        idmap.update(external_id: self.class.id_from_external_entity_hash(external_hash), last_push_to_external: Time.now, message: nil)

        return {idmap: idmap, completed_hash: map_and_complete_hash_with_connec_ids(external_hash, external_entity_name, id_refs_only_connec_entity)}
      # Update
      else
        return nil unless self.class.can_update_external?
        external_hash = update_external_entity(mapped_connec_entity, idmap.external_id, external_entity_name)

        completed_hash = map_and_complete_hash_with_connec_ids(external_hash, external_entity_name, id_refs_only_connec_entity)

        # Return the idmap to send it to connec! only if it's the first push of a singleton
        # or if there is a completed hash to send
        if (self.class.singleton? && idmap.last_push_to_external.nil?) || completed_hash
          idmap.update(last_push_to_external: Time.now, message: nil)
          return {idmap: idmap, completed_hash: completed_hash}
        end
        idmap.update(last_push_to_external: Time.now, message: nil)
      end
    rescue => e
      # TODO: improve the flexibility by adding the option for the developer to pass a custom/gem-dependent error
      case e
      when Maestrano::Connector::Rails::Exceptions::EntityNotFoundError
        idmap.update!(message: "The #{external_entity_name} record has been deleted in #{Maestrano::Connector::Rails::External.external_name}. Last attempt to sync on #{Time.now}", external_inactive: true)
        Maestrano::Connector::Rails::ConnectorLogger.log('info', @organization, "The #{idmap.external_entity} - #{idmap.external_id} record has been deleted. It is now set to inactive.")
      else
        # Store External error
        Maestrano::Connector::Rails::ConnectorLogger.log('error', @organization, "Error while pushing to #{Maestrano::Connector::Rails::External.external_name}: #{e}")
        Maestrano::Connector::Rails::ConnectorLogger.log('debug', @organization, "Error while pushing backtrace: #{e.backtrace.join("\n\t")}")
        idmap.update(message: e.message.truncate(255))
      end
    end

    # Nothing to send to Connec!
    nil
  end

  # To be implemented in each connector
  def create_external_entity(mapped_connec_entity, external_entity_name)
    Maestrano::Connector::Rails::ConnectorLogger.log('info', @organization, "Sending create #{external_entity_name}: #{mapped_connec_entity} to #{Maestrano::Connector::Rails::External.external_name}")
    raise 'Not implemented'
  end

  # To be implemented in each connector
  def update_external_entity(mapped_connec_entity, external_id, external_entity_name)
    Maestrano::Connector::Rails::ConnectorLogger.log('info', @organization, "Sending update #{external_entity_name} (id=#{external_id}): #{mapped_connec_entity} to #{Maestrano::Connector::Rails::External.external_name}")
    raise 'Not implemented'
  end

  # Returns a completed hash containing id_references with both the connec and external ids
  def map_and_complete_hash_with_connec_ids(external_hash, external_entity_name, connec_hash)
    return nil if connec_hash.empty?

    mapped_external_hash = map_to_connec(external_hash)
    references = Maestrano::Connector::Rails::ConnecHelper.format_references(self.class.references)

    Maestrano::Connector::Rails::ConnecHelper.merge_id_hashes(connec_hash, mapped_external_hash, references[:id_references])
  end

  # ----------------------------------------------
  #                 General methods
  # ----------------------------------------------
  # Returns a hash containing the mapped and filtered connec and external entities
  # * Discards entities that do not need to be pushed because
  #     * they date from before the date filtering limit (historical data)
  #     * they are lacking at least one reference (connec entities only)
  #     * they are inactive in the external application
  #     * they are flagged to not be shared (to_connec, to_external)
  #     * they have not been updated since their last push
  # * Discards entities from one of the two sources in case of conflict
  # * Maps not discarded entities and associates them with their idmap, or create one if there is none
  def consolidate_and_map_data(connec_entities, external_entities)
    Maestrano::Connector::Rails::ConnectorLogger.log('info', @organization, "Consolidating and mapping #{self.class.external_entity_name}/#{self.class.connec_entity_name}")
    return consolidate_and_map_singleton(connec_entities, external_entities) if self.class.singleton?

    mapped_connec_entities = consolidate_and_map_connec_entities(connec_entities, external_entities, self.class.references, self.class.external_entity_name)
    mapped_external_entities = consolidate_and_map_external_entities(external_entities, self.class.connec_entity_name)

    {connec_entities: mapped_connec_entities, external_entities: mapped_external_entities}
  end

  def consolidate_and_map_connec_entities(connec_entities, external_entities, references, external_entity_name)
    connec_entities.map { |entity|
      # Entity has been created before date filtering limit
      next nil if before_date_filtering_limit?(entity, false) && !@opts[:full_sync]

      # Unfold the id arrays
      # From that point on, the connec_entity contains only string of external ids
      unfold_hash = Maestrano::Connector::Rails::ConnecHelper.unfold_references(entity, references, @organization)
      entity = unfold_hash[:entity]
      next nil unless entity # discard if at least one record reference is missing
      connec_id = unfold_hash[:connec_id]
      id_refs_only_connec_entity = unfold_hash[:id_refs_only_connec_entity]

      if entity['id'].blank?
        # Expecting find_or_create to be mostly a create
        idmap = self.class.find_or_create_idmap(organization_id: @organization.id, name: self.class.object_name_from_connec_entity_hash(entity), external_entity: external_entity_name.downcase, connec_id: connec_id)
        next map_connec_entity_with_idmap(entity, external_entity_name, idmap, id_refs_only_connec_entity)
      end

      # Expecting find_or_create to be mostly a find
      idmap = self.class.find_or_create_idmap(external_id: entity['id'], organization_id: @organization.id, external_entity: external_entity_name.downcase, connec_id: connec_id)
      idmap.update(name: self.class.object_name_from_connec_entity_hash(entity))

      next nil if idmap.external_inactive || !idmap.to_external || (!@opts[:full_sync] && not_modified_since_last_push_to_external?(idmap, entity))

      # Check for conflict with entities from external
      solve_conflict(entity, external_entities, external_entity_name, idmap, id_refs_only_connec_entity)
    }.compact
  end

  def consolidate_and_map_external_entities(external_entities, connec_entity_name)
    external_entities.map { |entity|
      # Entity has been created before date filtering limit
      next nil if before_date_filtering_limit?(entity) && !@opts[:full_sync]

      entity_id = self.class.id_from_external_entity_hash(entity)
      idmap = self.class.find_or_create_idmap(external_id: entity_id, organization_id: @organization.id, connec_entity: connec_entity_name.downcase)

      # Not pushing entity to Connec!
      next nil unless idmap.to_connec

      # Not pushing to Connec! and flagging as inactive if inactive in external application
      inactive = self.class.inactive_from_external_entity_hash?(entity)
      idmap.update(external_inactive: inactive, name: self.class.object_name_from_external_entity_hash(entity))
      next nil if inactive

      # Entity has not been modified since its last push to connec!
      next nil if !@opts[:full_sync] && not_modified_since_last_push_to_connec?(idmap, entity)

      map_external_entity_with_idmap(entity, connec_entity_name, idmap)
    }.compact
  end

  def consolidate_and_map_singleton(connec_entities, external_entities)
    return {connec_entities: [], external_entities: []} if external_entities.empty? && connec_entities.empty?

    idmap = self.class.find_or_create_idmap(organization_id: @organization.id)
    # No to_connec, to_external and inactive consideration here as we don't expect those workflow for singleton

    keep_external = if external_entities.empty?
                      false
                    elsif connec_entities.empty?
                      true
                    elsif @opts.key?(:connec_preemption)
                      !@opts[:connec_preemption]
                    else
                      !is_connec_more_recent?(connec_entities.first, external_entities.first)
                    end

    if keep_external
      idmap.update(external_id: self.class.id_from_external_entity_hash(external_entities.first), name: self.class.object_name_from_external_entity_hash(external_entities.first))
      return {connec_entities: [], external_entities: [{entity: map_to_connec(external_entities.first), idmap: idmap}]}
    else
      unfold_hash = Maestrano::Connector::Rails::ConnecHelper.unfold_references(connec_entities.first, self.class.references, @organization)
      entity = unfold_hash[:entity]
      idmap.update(name: self.class.object_name_from_connec_entity_hash(entity), connec_id: unfold_hash[:connec_id])
      idmap.update(external_id: self.class.id_from_external_entity_hash(external_entities.first)) unless external_entities.empty?
      return {connec_entities: [{entity: map_to_external(entity), idmap: idmap, id_refs_only_connec_entity: {}}], external_entities: []}
    end
  end

  # ----------------------------------------------
  #             Internal helper methods
  # ----------------------------------------------
  private

    # array_with_idmap must be an array of hashes with a key idmap
    # proc is a lambda to create a batch_op from an element of the array
    # Perform batch calls on Connec API and parse the response
    def batch_calls(array_with_idmap, proc, connec_entity_name, id_update_only = false)
      request_per_call = @opts[:request_per_batch_call] || 100
      start = 0
      while start < array_with_idmap.size
        # Prepare batch request
        batch_entities = array_with_idmap.slice(start, request_per_call)
        batch_request = {sequential: true, ops: []}

        batch_entities.each do |id|
          batch_request[:ops] << proc.call(id)
        end

        # Batch call
        log_info = id_update_only ? 'with only ids' : ''
        Maestrano::Connector::Rails::ConnectorLogger.log('info', @organization, "Sending batch request to Connec! #{log_info} for #{self.class.normalize_connec_entity_name(connec_entity_name)}. Batch_request_size: #{batch_request[:ops].size}. Call_number: #{(start / request_per_call) + 1}")
        response = @connec_client.batch(batch_request)
        Maestrano::Connector::Rails::ConnectorLogger.log('debug', @organization, "Received batch response from Connec! for #{self.class.normalize_connec_entity_name(connec_entity_name)}: #{response}")
        raise "No data received from Connec! when trying to send batch request #{log_info} for #{self.class.connec_entity_name.pluralize}" unless response && !response.body.blank?
        response = JSON.parse(response.body)

        # Parse batch response
        # Update idmaps with either connec_id and timestamps, or a error message
        response['results'].each_with_index do |result, index|
          if result['status'] == 200
            batch_entities[index][:idmap].update(connec_id: result['body'][self.class.normalize_connec_entity_name(connec_entity_name)]['id'].find { |id| id['provider'] == 'connec' }['id'], last_push_to_connec: Time.now, message: nil) unless id_update_only # id_update_only only apply for 200 as it's doing PUTs
          elsif result['status'] == 201
            batch_entities[index][:idmap].update(connec_id: result['body'][self.class.normalize_connec_entity_name(connec_entity_name)]['id'].find { |id| id['provider'] == 'connec' }['id'], last_push_to_connec: Time.now, message: nil)
          else
            Maestrano::Connector::Rails::ConnectorLogger.log('warn', @organization, "Error while pushing to Connec!: #{result['body']}")
            # TODO, better error message
            batch_entities[index][:idmap].update(message: result['body'].to_s.truncate(255))
          end
        end

        start += request_per_call
      end
    end

    def not_modified_since_last_push_to_connec?(idmap, entity)
      not_modified = idmap.last_push_to_connec && idmap.last_push_to_connec > self.class.last_update_date_from_external_entity_hash(entity)
      Maestrano::Connector::Rails::ConnectorLogger.log('info', @organization, "Discard #{Maestrano::Connector::Rails::External.external_name} #{self.class.external_entity_name} : #{entity}") if not_modified
      not_modified
    end

    def not_modified_since_last_push_to_external?(idmap, entity)
      not_modified = idmap.last_push_to_external && idmap.last_push_to_external > entity['updated_at']
      Maestrano::Connector::Rails::ConnectorLogger.log('info', @organization, "Discard Connec! #{self.class.connec_entity_name} : #{entity}") if not_modified
      not_modified
    end

    def before_date_filtering_limit?(entity, external = true)
      @organization.date_filtering_limit && @organization.date_filtering_limit > (external ? self.class.creation_date_from_external_entity_hash(entity) : entity['created_at'])
    end

    def is_connec_more_recent?(connec_entity, external_entity)
      connec_entity['updated_at'] > self.class.last_update_date_from_external_entity_hash(external_entity)
    end

    # This methods try to find a external entity among all the external entities matching the connec (mapped) one (same id)
    # If it does not find any, there is no conflict, and it returns the mapped connec entity
    # If it finds one, the conflict is solved either with options or using the entities timestamps
    #   If the connec entity is kept, it is returned mapped and the matching external entity is discarded (deleted from the array)
    #   Else the method returns nil, meaning the connec entity is discarded
    def solve_conflict(connec_entity, external_entities, external_entity_name, idmap, id_refs_only_connec_entity)
      # Here the connec_entity['id'] is an external id (String) because the entity has been unfolded.
      external_entity = external_entities.find { |entity| connec_entity['id'] == self.class.id_from_external_entity_hash(entity) }
      # No conflict
      return map_connec_entity_with_idmap(connec_entity, external_entity_name, idmap, id_refs_only_connec_entity) unless external_entity

      # Conflict
      # We keep the most recently updated entity
      keep_connec = @opts.key?(:connec_preemption) ? @opts[:connec_preemption] : is_connec_more_recent?(connec_entity, external_entity)

      if keep_connec
        Maestrano::Connector::Rails::ConnectorLogger.log('info', @organization, "Conflict between #{Maestrano::Connector::Rails::External.external_name} #{external_entity_name} #{external_entity} and Connec! #{self.class.connec_entity_name} #{connec_entity}. Entity from Connec! kept")
        external_entities.delete(external_entity)
        map_connec_entity_with_idmap(connec_entity, external_entity_name, idmap, id_refs_only_connec_entity)
      else
        Maestrano::Connector::Rails::ConnectorLogger.log('info', @organization, "Conflict between #{Maestrano::Connector::Rails::External.external_name} #{external_entity_name} #{external_entity} and Connec! #{self.class.connec_entity_name} #{connec_entity}. Entity from external kept")
        nil
      end
    end

    def map_connec_entity_with_idmap(connec_entity, external_entity_name, idmap, id_refs_only_connec_entity)
      {entity: map_to_external(connec_entity, idmap.last_push_to_external.nil?), idmap: idmap, id_refs_only_connec_entity: id_refs_only_connec_entity}
    end

    def map_external_entity_with_idmap(external_entity, connec_entity_name, idmap)
      {entity: map_to_connec(external_entity, idmap.last_push_to_connec.nil?), idmap: idmap}
    end

    def fetch_connec(uri)
      Maestrano::Connector::Rails::ConnectorLogger.log('debug', @organization, "Fetching data from connec entity=#{self.class.connec_entity_name}, url=#{uri}")
      response = @connec_client.get(uri)

      raise "No data received from Connec! when trying to fetch #{self.class.normalized_connec_entity_name}" unless response && !response.body.blank?

      response_hash = JSON.parse(response.body)
      Maestrano::Connector::Rails::ConnectorLogger.log('debug', @organization, "Received response for entity=#{self.class.connec_entity_name}, response=#{response_hash}")
      raise "Received unrecognized Connec! data when trying to fetch #{self.class.normalized_connec_entity_name}: #{response_hash}" unless response_hash[self.class.normalized_connec_entity_name]

      response_hash
    end
end
