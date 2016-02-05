module Maestrano::Connector::Rails
  class SynchronizationJob < ::ActiveJob::Base
    queue_as :default

    # Supported options:
    #  * :forced => true  synchronization has been triggered manually (for logging purposes only)
    #  * :only_entities => [person, tasks_list]
    #  * :full_sync => true  synchronization is performed without date filtering
    #  * :connec_preemption => true|false : preemption is always|never given to connec in case of conflict (if not set, the most recently updated entity is kept)
    def perform(organization, opts)
      return unless organization.sync_enabled
      ConnectorLogger.log('info', organization, "Start synchronization, opts=#{opts}")
      current_synchronization = Synchronization.create_running(organization)

      begin
        last_synchronization = Synchronization.where(organization_id: organization.id, status: 'SUCCESS', partial: false).order(updated_at: :desc).first
        connec_client = Maestrano::Connec::Client.new(organization.uid)
        external_client = External.get_client(organization)

        if opts[:only_entities]
          ConnectorLogger.log('info', organization, "Synchronization is partial and will synchronize only #{opts[:only_entities].join(' ')}")
          # The synchronization is marked as partial and will not be considered as the last-synchronization for the next sync
          current_synchronization.set_partial
          opts[:only_entities].each do |entity|
            sync_entity(entity, organization, connec_client, external_client, last_synchronization, opts)
          end
        else
          organization.synchronized_entities.select{|k, v| v}.keys.each do |entity|
            sync_entity(entity.to_s, organization, connec_client, external_client, last_synchronization, opts)
          end
        end

        ConnectorLogger.log('info', organization, "Finished synchronization, organization=#{organization.uid}, status=success")
        current_synchronization.set_success
      rescue => e
        ConnectorLogger.log('info', organization, "Finished synchronization, organization=#{organization.uid}, status=error, message=#{e.message} backtrace=#{e.backtrace.join("\n\t")}")
        current_synchronization.set_error(e.message)
      end
    end

    def sync_entity(entity, organization, connec_client, external_client, last_synchronization, opts)
      entity_instance = "Entities::#{entity.titleize.split.join}".constantize.new

      external_entities = entity_instance.get_external_entities(external_client, last_synchronization, organization, opts)
      connec_entities = entity_instance.get_connec_entities(connec_client, last_synchronization, organization, opts)
      entity_instance.consolidate_and_map_data(connec_entities, external_entities, organization, opts)
      entity_instance.push_entities_to_external(external_client, connec_entities, organization)
      entity_instance.push_entities_to_connec(connec_client, external_entities, organization)
    end
  end
end