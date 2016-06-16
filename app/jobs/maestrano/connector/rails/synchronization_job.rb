module Maestrano::Connector::Rails
  class SynchronizationJob < ::ActiveJob::Base
    queue_as :default

    # Supported options:
    #  * :forced => true  synchronization has been triggered manually
    #  * :only_entities => [person, tasks_list]
    #  * :full_sync => true  synchronization is performed without date filtering
    #  * :connec_preemption => true|false : preemption is always|never given to connec in case of conflict (if not set, the most recently updated entity is kept)
    def perform(organization, opts={})
      return unless organization.sync_enabled

      # Check if previous synchronization is still running
      if Synchronization.where(organization_id: organization.id, status: 'RUNNING').where(created_at: (30.minutes.ago..Time.now)).exists?
        ConnectorLogger.log('info', organization, "Synchronization skipped: Previous synchronization is still running")
        return
      end

      # Check if recovery mode: last 3 synchronizations have failed
      if !opts[:forced] && organization.last_three_synchronizations_failed? \
          && organization.synchronizations.order(created_at: :desc).limit(1).first.updated_at > 1.day.ago
        ConnectorLogger.log('info', organization, "Synchronization skipped: Recovery mode (three previous synchronizations have failed)")
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
        if last_synchronization.nil?
          ConnectorLogger.log('info', organization, "First synchronization ever. Doing two half syncs to allow smart merging to work its magic.")
          [{skip_connec: true}, {skip_external: true}].each do |opt|
            organization.synchronized_entities.select{|k, v| v}.keys.each do |entity|
              sync_entity(entity.to_s, organization, connec_client, external_client, last_synchronization_date, opts.merge(opt))
            end
          end
        elsif opts[:only_entities]
          ConnectorLogger.log('info', organization, "Synchronization is partial and will synchronize only #{opts[:only_entities].join(' ')}")
          # The synchronization is marked as partial and will not be considered as the last-synchronization for the next sync
          current_synchronization.set_partial
          opts[:only_entities].each do |entity|
            sync_entity(entity, organization, connec_client, external_client, last_synchronization_date, opts)
          end
        else
          organization.synchronized_entities.select{|k, v| v}.keys.each do |entity|
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
      entity_instance = "Entities::#{entity_name.titleize.split.join}".constantize.new(organization, connec_client, external_client, opts.dup)

      entity_instance.before_sync(last_synchronization_date)
      external_entities = entity_instance.get_external_entities_wrapper(last_synchronization_date)
      connec_entities = entity_instance.get_connec_entities(last_synchronization_date)
      mapped_entities = entity_instance.consolidate_and_map_data(connec_entities, external_entities)
      entity_instance.push_entities_to_external(mapped_entities[:connec_entities])
      entity_instance.push_entities_to_connec(mapped_entities[:external_entities])
      entity_instance.after_sync(last_synchronization_date)
    end
  end
end