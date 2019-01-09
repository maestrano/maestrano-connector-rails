module Maestrano::Connector::Rails::Concerns::SynchronizationJob
  extend ActiveSupport::Concern

  included do
    queue_as :default
  end

  module ClassMethods
    def enqueued?(organization_id)
      Maestrano::Connector::Rails::SynchronizationJob.find_job(organization_id).present? || Maestrano::Connector::Rails::SynchronizationJob.find_running_job(organization_id).present?
    end

    def find_job(organization_id)
      queue = Sidekiq::Queue.new(:default)
      queue.find do |job|
        job_organization_id = begin
                                job.item['args'][0]['arguments'].first
                              rescue
                                false
                              end
        organization_id == job_organization_id
      end
    end

    def find_running_job(organization_id)
      Sidekiq::Workers.new.find do |_, _, work|
        job_organization_id = begin
                                work['payload']['args'][0]['arguments'].first
                              rescue
                                false
                              end
        work['queue'] == 'default' && organization_id == job_organization_id
      end
    rescue
      nil
    end
  end

  # Supported options:
  #  * :forced => true  synchronization has been triggered manually
  #  * :only_entities => [person, tasks_list]
  #  * :full_sync => true  synchronization is performed without date filtering
  #  * :connec_preemption => true|false : preemption is always|never given to connec in case of conflict (if not set, the most recently updated entity is kept)
  #  * :sync_from => ActiveSupport::TimeWithZone : sync from this date.
  def perform(organization_id, opts = {})
    organization = Maestrano::Connector::Rails::Organization.find(organization_id)
    return unless organization&.sync_enabled

    # Check if previous synchronization is still running
    if Maestrano::Connector::Rails::Synchronization.where(organization_id: organization.id, status: 'RUNNING').where(created_at: (30.minutes.ago..Time.now.utc)).exists?
      Maestrano::Connector::Rails::ConnectorLogger.log('info', organization, 'Synchronization skipped: Previous synchronization is still running')
      return
    end

    # Check if recovery mode: last 3 synchronizations have failed
    if !opts[:forced] && organization.last_three_synchronizations_failed? \
        && organization.synchronizations.order(created_at: :desc).limit(1).first.updated_at > 1.day.ago
      Maestrano::Connector::Rails::ConnectorLogger.log('info', organization, 'Synchronization skipped: Recovery mode (three previous synchronizations have failed)')
      return
    end

    # Trigger synchronization
    Maestrano::Connector::Rails::ConnectorLogger.log('info', organization, "Start synchronization, opts=#{opts}")
    current_synchronization = Maestrano::Connector::Rails::Synchronization.create_running(organization)

    begin
      last_synchronization = organization.last_successful_synchronization
      sync_from_date = opts[:sync_from] || organization.last_synchronization_date
      connec_client = Maestrano::Connector::Rails::ConnecHelper.get_client(organization)
      external_client = Maestrano::Connector::Rails::External.get_client(organization)

      # First synchronization should be from external to Connec! only to let the smart merging works
      # We do a doube sync: only from external, then only from connec!
      # We also do batched sync as the first one can be quite huge
      if last_synchronization.nil?
        Maestrano::Connector::Rails::ConnectorLogger.log('info', organization, 'First synchronization ever. Doing two half syncs to allow smart merging to work its magic.')
        organization.synchronized_entities.each do |entity, settings|
          next unless settings[:can_push_to_connec] || settings[:can_push_to_external]

          Maestrano::Connector::Rails::ConnectorLogger.log('info', organization, "First synchronization ever. Doing half sync from external for #{entity}.")
          first_sync_entity(entity.to_s, organization, connec_client, external_client, sync_from_date, opts, true)
          Maestrano::Connector::Rails::ConnectorLogger.log('info', organization, "First synchronization ever. Doing half sync from Connec! for #{entity}.")
          first_sync_entity(entity.to_s, organization, connec_client, external_client, sync_from_date, opts, false)
        end
      elsif opts[:only_entities]
        Maestrano::Connector::Rails::ConnectorLogger.log('info', organization, "Synchronization is partial and will synchronize only #{opts[:only_entities].join(' ')}")
        # The synchronization is marked as partial and will not be considered as the last-synchronization for the next sync
        current_synchronization.mark_as_partial
        opts[:only_entities].each do |entity|
          sync_entity(entity, organization, connec_client, external_client, sync_from_date, opts)
        end
      else
        organization.synchronized_entities.each do |entity, settings|
          next unless settings[:can_push_to_connec] || settings[:can_push_to_external]

          sync_entity(entity.to_s, organization, connec_client, external_client, sync_from_date, opts)
        end
      end

      Maestrano::Connector::Rails::ConnectorLogger.log('info', organization, "Finished synchronization, organization=#{organization.uid}, status=success")
      current_synchronization.mark_as_success
    rescue => e
      Maestrano::Connector::Rails::ConnectorLogger.log('warn', organization, "Finished synchronization, organization=#{organization.uid}, status=error, message=\"#{e.message}\" backtrace=\"#{e.backtrace}\"")
      current_synchronization.mark_as_error(e.message)
    end
  end

  def sync_entity(entity_name, organization, connec_client, external_client, sync_from_date, opts)
    entity_instance = instanciate_entity(entity_name, organization, connec_client, external_client, opts)

    perform_sync(entity_instance, sync_from_date)
  end

  # Does a batched sync on either external or connec!
  def first_sync_entity(entity_name, organization, connec_client, external_client, sync_from_date, opts, external = true)
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

      perform_hash = perform_sync(entity_instance, sync_from_date, external)
      entities_count = perform_hash[:count]

      # Safety: if the connector does not implement batched calls but has exactly limit entities
      # There is a risk of infinite loop
      # We're comparing the first record to check that it is different
      first_record = Digest::MD5.hexdigest(perform_hash[:first].to_s)
      break if last_first_record && first_record == last_first_record

      last_first_record = first_record

      skip += limit
    end
  end

  private

    def instanciate_entity(entity_name, organization, connec_client, external_client, opts)
      "Entities::#{entity_name.titleize.split.join}".constantize.new(organization, connec_client, external_client, opts.dup)
    end

    # Perform the sync and return the entities_count for either external or connec
    def perform_sync(entity_instance, sync_from_date, external = true)
      entity_instance.before_sync(sync_from_date)
      external_entities = entity_instance.get_external_entities_wrapper(sync_from_date)
      connec_entities = entity_instance.get_connec_entities(sync_from_date)
      mapped_entities = entity_instance.consolidate_and_map_data(connec_entities, external_entities)
      entity_instance.push_entities_to_external(mapped_entities[:connec_entities])
      entity_instance.push_entities_to_connec(mapped_entities[:external_entities])
      entity_instance.after_sync(sync_from_date)

      entity_instance.class.count_and_first(external ? external_entities : connec_entities)
    end
end
