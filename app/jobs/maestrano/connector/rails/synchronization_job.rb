module Maestrano::Connector::Rails
  class SynchronizationJob < ::ActiveJob::Base
    queue_as :default

    # Supported options:
    #  * :forced => true  synchronization has been triggered manually
    #  * :only_entities => [person, tasks_list]
    #  * :full_sync => true  synchronization is performed without date filtering
    #  * :connec_preemption => true|false : preemption is always|never given to connec in case of conflict (if not set, the most recently updated entity is kept)
    def perform(organization, opts = {})
      return unless organization.sync_enabled

      # Check if previous synchronization is still running
      if Synchronization.where(organization_id: organization.id, status: 'RUNNING').where(created_at: (30.minutes.ago..Time.now)).exists?
        ConnectorLogger.log('info', organization, 'Synchronization skipped: Previous synchronization is still running')
        return
      end

      # Check if recovery mode: last 3 synchronizations have failed
      if !opts[:forced] && organization.last_three_synchronizations_failed? \
          && organization.synchronizations.order(created_at: :desc).limit(1).first.updated_at > 1.day.ago
        ConnectorLogger.log('info', organization, 'Synchronization skipped: Recovery mode (three previous synchronizations have failed)')
        return
      end

      # Trigger synchronization
      ConnectorLogger.log('info', organization, "Start synchronization, opts=#{opts}")
      current_synchronization = Synchronization.create_running(organization)

      begin
        last_synchronization = organization.last_successful_synchronization
        last_synchronization_date = organization.last_synchronization_date
        connec_client = ConnecHelper.get_client(organization)
        external_client = External.get_client(organization)

        # First synchronization should be from external to Connec! only to let the smart merging works
        # We do a doube sync: only from external, then only from connec!
        # We also do batched sync as the first one can be quite huge
        if last_synchronization.nil?
          ConnectorLogger.log('info', organization, 'First synchronization ever. Doing two half syncs to allow smart merging to work its magic.')
          organization.synchronized_entities.select { |k, v| v }.keys.each do |entity|
            ConnectorLogger.log('info', organization, "First synchronization ever. Doing half sync from external for #{entity}.")
            first_sync_entity(entity.to_s, organization, connec_client, external_client, last_synchronization_date, opts, true)
            ConnectorLogger.log('info', organization, "First synchronization ever. Doing half sync from Connec! for #{entity}.")
            first_sync_entity(entity.to_s, organization, connec_client, external_client, last_synchronization_date, opts, false)
          end
        elsif opts[:only_entities]
          ConnectorLogger.log('info', organization, "Synchronization is partial and will synchronize only #{opts[:only_entities].join(' ')}")
          # The synchronization is marked as partial and will not be considered as the last-synchronization for the next sync
          current_synchronization.set_partial
          opts[:only_entities].each do |entity|
            sync_entity(entity, organization, connec_client, external_client, last_synchronization_date, opts)
          end
        else
          organization.synchronized_entities.select { |_k, v| v }.keys.each do |entity|
            sync_entity(entity.to_s, organization, connec_client, external_client, last_synchronization_date, opts)
          end
        end

        ConnectorLogger.log('info', organization, "Finished synchronization, organization=#{organization.uid}, status=success")
        current_synchronization.set_success
      rescue => e
        ConnectorLogger.log('info', organization, "Finished synchronization, organization=#{organization.uid}, status=error, message=#{e.message} backtrace=#{e.backtrace.join("\n\t")}")
        current_synchronization.set_error(e.message)
      end
    end

    def sync_entity(entity_name, organization, connec_client, external_client, last_synchronization_date, opts)
      entity_instance = instanciate_entity(entity_name, organization, connec_client, external_client, opts)

      perform_sync(entity_instance, last_synchronization_date)
    end

    # Does a batched sync on either external or connec!
    def first_sync_entity(entity_name, organization, connec_client, external_client, last_synchronization_date, opts, external = true)
      limit = Settings.first_sync_batch_size || 50
      skip = 0
      entities_count = limit
      last_first_record = nil

      h = {__limit: limit}
      external ? h[:__skip_connec] = true : h[:__skip_external] = true
      entity_instance = instanciate_entity(entity_name, organization, connec_client, external_client, opts.merge(h))

      # IF entities_count > limit
      # This first sync feature is probably not implemented in the connector
      # because it fetched more than the expected number of entities
      # No need to fetch it a second Time
      # ELSIF entities_count < limit
      # No more entities to fetch
      while entities_count == limit
        entity_instance.opts_merge!(__skip: skip)

        perform_hash = perform_sync(entity_instance, last_synchronization_date, external)
        entities_count = perform_hash[:count]

        # Safety: if the connector does not implement batched calls but has exactly limit entities
        # There is a risk of infinite loop
        # We're comparing the first record to check that it is different
        first_record = perform_hash[:first]
        break if last_first_record && Digest::MD5.hexdigest(first_record.to_s) == Digest::MD5.hexdigest(last_first_record.to_s)
        last_first_record = first_record

        skip += limit
      end
    end

    private

      def instanciate_entity(entity_name, organization, connec_client, external_client, opts)
        "Entities::#{entity_name.titleize.split.join}".constantize.new(organization, connec_client, external_client, opts.dup)
      end

      # Perform the sync and return the entities_count for either external or connec
      def perform_sync(entity_instance, last_synchronization_date, external = true)
        entity_instance.before_sync(last_synchronization_date)
        external_entities = entity_instance.get_external_entities_wrapper(last_synchronization_date)
        connec_entities = entity_instance.get_connec_entities(last_synchronization_date)
        mapped_entities = entity_instance.consolidate_and_map_data(connec_entities, external_entities)
        entity_instance.push_entities_to_external(mapped_entities[:connec_entities])
        entity_instance.push_entities_to_connec(mapped_entities[:external_entities])
        entity_instance.after_sync(last_synchronization_date)
        
        entity_instance.class.count_and_first(external ? external_entities : connec_entities)
      end
  end
end
