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

    def currency_check_fields
      nil
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
        next_page = response_hash['pagination']['next'].gsub(/\A(.*)\/#{self.class.normalized_connec_entity_name}/, self.class.normalized_connec_entity_name)

        response_hash = fetch_connec(next_page)
        entities.concat response_hash[self.class.normalized_connec_entity_name]
      end
    end

    entities.flatten!

    sanitized_entities = sanitizer_profile? ? Maestrano::Connector::Rails::Services::DataSanitizer.new('connec_sanitizer_profile.yml').sanitize(external_entity_name.downcase, entities) : entities
    Maestrano::Connector::Rails::ConnectorLogger.log('info', @organization, "Received data: Source=Connec!, Entity=#{self.class.connec_entity_name}, Data=#{sanitized_entities}")

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
    unless @organization.push_to_connec_enabled?(self)
      Maestrano::Connector::Rails::ConnectorLogger.log('info', @organization, "#{Maestrano::Connector::Rails::External.external_name}-#{self.class.external_entity_name.pluralize} not sent to Connec! Push disabled or name not found")
      return
    end

    Maestrano::Connector::Rails::ConnectorLogger.log('info', @organization, "Sending #{Maestrano::Connector::Rails::External.external_name} #{self.class.external_entity_name.pluralize} to Connec! #{connec_entity_name.pluralize}")

    # As we're doing only POST, we use the idmaps to filter out updates
    unless self.class.can_update_connec?
      mapped_external_entities_with_idmaps.reject! { |mapped_external_entity_with_idmap| mapped_external_entity_with_idmap[:idmap].connec_id }
    end

    if self.class.currency_check_fields
      mapped_external_entities_with_idmaps.each do |mapped_external_entity_with_idmap|
        id_map = mapped_external_entity_with_idmap[:idmap]
        next unless id_map&.metadata&.dig(:ignore_currency_update)

        self.class.currency_check_fields.each do |field|
          mapped_external_entity_with_idmap[:entity].delete(field)
        end
      end
    end

    proc = ->(mapped_external_entity_with_idmap) { batch_op('post', mapped_external_entity_with_idmap[:entity], nil, self.class.normalize_connec_entity_name(connec_entity_name)) }
    batch_calls(mapped_external_entities_with_idmaps, proc, connec_entity_name)
  end

  # Helper method to build an op for batch call
  # See http://maestrano.github.io/connec/#api-|-batch-calls
  def batch_op(method, mapped_external_entity, id, connec_entity_name)
    sanitized_external_entity = sanitizer_profile? ? Maestrano::Connector::Rails::Services::DataSanitizer.new('connec_sanitizer_profile.yml').sanitize(connec_entity_name, mapped_external_entity) : mapped_external_entity
    Maestrano::Connector::Rails::ConnectorLogger.log('info', @organization, "Sending #{method.upcase} #{connec_entity_name}: #{sanitized_external_entity} to Connec! (Preparing batch request)")
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
    unless @organization.push_to_external_enabled?(self)
      Maestrano::Connector::Rails::ConnectorLogger.log('info', @organization, "#{self.class.connec_entity_name.pluralize} not sent to External! Push disabled or name not found")
      return
    end

    Maestrano::Connector::Rails::ConnectorLogger.log('info', @organization, "Sending Connec! #{self.class.connec_entity_name.pluralize} to #{Maestrano::Connector::Rails::External.external_name} #{external_entity_name.pluralize}")

    entities_to_send_to_connec = mapped_connec_entities_with_idmaps.map { |mapped_connec_entity_with_idmap|
      push_entity_to_external(mapped_connec_entity_with_idmap, external_entity_name)
    }.compact

    # Send the external ids to connec if it was a creation
    # or if there are some sub entities ids to send (completed_hash)
    return if entities_to_send_to_connec.empty?

    # Build a batch op from an idmap and a completed hash
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
        Maestrano::Connector::Rails::ConnectorLogger.log('debug', @organization, "Error while pushing backtrace: #{e.backtrace}")
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
    Maestrano::Connector::Rails::Services::DataConsolidator.new(@organization, self, @opts).consolidate_connec_entities(connec_entities, external_entities, references, external_entity_name)
  end

  def consolidate_and_map_external_entities(external_entities, connec_entity_name)
    Maestrano::Connector::Rails::Services::DataConsolidator.new(@organization, self, @opts).consolidate_external_entities(external_entities, connec_entity_name)
  end

  def consolidate_and_map_singleton(connec_entities, external_entities)
    Maestrano::Connector::Rails::Services::DataConsolidator.new(@organization, self, @opts).consolidate_singleton(connec_entities, external_entities)
  end

  # ----------------------------------------------
  #             Internal helper methods
  # ----------------------------------------------
  private

    # array_with_idmap must be an array of hashes with a key idmap
    # proc is a lambda to create a batch_op from an element of the array
    # Perform batch calls on Connec API and parse the response
    def batch_calls(array_with_idmap, proc, connec_entity_name, id_update_only = false)
      request_per_call = @opts[:request_per_batch_call] || 50
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
        response = Retriable.with_context(:connec) { @connec_client.batch(batch_request) }
        sanitized_response = sanitizer_profile? ? Maestrano::Connector::Rails::Services::DataSanitizer.new('connec_sanitizer_profile.yml').sanitize(self.class.normalize_connec_entity_name(connec_entity_name), (JSON.parse(response.body)['results'].map { |h| h['body'] })) : response
        Maestrano::Connector::Rails::ConnectorLogger.log('debug', @organization, "Received batch response from Connec! for #{self.class.normalize_connec_entity_name(connec_entity_name)}: #{sanitized_response}")
        raise "No data received from Connec! when trying to send batch request #{log_info} for #{self.class.connec_entity_name.pluralize}" unless response && response.body.present?

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

    def fetch_connec(uri)
      Maestrano::Connector::Rails::ConnectorLogger.log('debug', @organization, "Fetching data from connec entity=#{self.class.connec_entity_name}, url=#{uri}")
      response = Retriable.with_context(:connec) { @connec_client.get(uri) }

      raise "No data received from Connec! when trying to fetch #{self.class.normalized_connec_entity_name}" unless response && response.body.present?

      response_hash = JSON.parse(response.body)

      sanitized_response_hash = sanitizer_profile? ? Maestrano::Connector::Rails::Services::DataSanitizer.new('connec_sanitizer_profile.yml').sanitize(self.class.connec_entity_name, response_hash['results'].map { |h| h['body'] }) : response_hash

      Maestrano::Connector::Rails::ConnectorLogger.log('debug', @organization, "Received response for entity=#{self.class.connec_entity_name}, response=#{sanitized_response_hash}")
      raise "Received unrecognized Connec! data when trying to fetch #{self.class.normalized_connec_entity_name}: #{response_hash}" unless response_hash[self.class.normalized_connec_entity_name]

      response_hash
    end

    def sanitizer_profile?(profile = 'connec_sanitizer_profile.yml')
      File.file?(Rails.root.join('config', 'profiles', profile))
    end
end
