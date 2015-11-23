module Maestrano::Connector::Rails
  class SynchronizationJob < Struct.new(:organization, :opts)

    # Supported options:
    #  * :forced => true  synchronization has been triggered manually (for logging purposes only)
    #  * :only_entities => [person, tasks_list]
    #  * :full_sync => true  synchronization is performed without date filtering
    def perform
      Rails.logger.info "Start synchronization, organization=#{organization.uid} #{opts[:forced] ? 'forced=true' : ''}"
      current_synchronization = Synchronization.create(organization_id: organization.id, status: 'RUNNING')

      begin
        last_synchronization = Synchronization.where(organization_id: organization.id, status: 'SUCCESS', partial: false).order(updated_at: :desc).first
        connec_client = Maestrano::Connec::Client.new(organization.uid)
        external_client = External.get_client(organization)

        if opts[:only_entities]
          Rails.logger.info "Synchronization is partial and will synchronize only #{opts[:only_entities].join(' ')}"
          # The synchronization is marked as partial and will not be considered as the last-synchronization for the next sync
          current_synchronization.update_attributes(partial: true)
          opts[:only_entities].each do |entity|
            sync_entity(entity, organization, connec_client, external_client, last_synchronization, opts)
          end
        else
          organization.synchronized_entities.select{|k, v| v}.keys.each do |entity|
            sync_entity(entity.to_s, organization, connec_client, external_client, last_synchronization, opts)
          end
        end

        Rails.logger.info "Finished synchronization, organization=#{organization.uid}, status=success"
        current_synchronization.update_attributes(status: 'SUCCESS')
      rescue => e
        Rails.logger.info "Finished synchronization, organization=#{organization.uid}, status=error, message=#{e.message} backtrace=#{e.backtrace.join("\n\t")}"
        current_synchronization.update_attributes(status: 'ERROR', message: e.message)
      end
    end

    def sync_entity(entity, organization, connec_client, external_client, last_synchronization, opts)
      entity_class = "Entities::#{entity.titleize.split.join}".constantize.new
      entity_class.set_mapper_organization(organization.id)

      external_entities = entity_class.get_external_entities(external_client, last_synchronization, opts)
      connec_entities = entity_class.get_connec_entities(connec_client, last_synchronization, opts)
      entity_class.consolidate_and_map_data(connec_entities, external_entities, organization)
      entity_class.push_entities_to_external(external_client, connec_entities)
      entity_class.push_entities_to_connec(connec_client, external_entities)

      entity_class.unset_mapper_organization
    end
  end
end