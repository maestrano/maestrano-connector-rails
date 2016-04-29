class Maestrano::ConnecController < Maestrano::Rails::WebHookController

  def notifications
    Rails.logger.debug "Received notification from Connec!: #{params}"

    begin
      params.except(:tenant, :controller, :action).each do |entity_name, entities|

        entity_instance_hash = find_entity_instance(entity_name)
        next Rails.logger.info "Received notification from Connec! for unknow entity: #{entity_name}" unless entity_instance_hash

        entity_instance = entity_instance_hash[:instance]

        entities.each do |entity|
          organization = Maestrano::Connector::Rails::Organization.find_by_uid_and_tenant(entity[:group_id], params[:tenant])
          next Rails.logger.warn "Received notification from Connec! for unknown group or group without oauth: #{entity['group_id']} (tenant: #{params[:tenant]})" unless organization && organization.oauth_uid
          next unless organization.sync_enabled && organization.synchronized_entities[entity_instance_hash[:name].to_sym]


          Maestrano::Connector::Rails::ConnectorLogger.log('info', organization, "Received entity from Connec! webhook: Entity=#{entity_name}, Data=#{entity}")
          connec_client = Maestrano::Connec::Client[organization.tenant].new(organization.uid)
          external_client = Maestrano::Connector::Rails::External.get_client(organization)
          last_synchronization = organization.last_successful_synchronization

          entity_instance.before_sync(connec_client, external_client, last_synchronization, organization, {})
          # Build expected input for consolidate_and_map_data
          if entity_instance_hash[:is_complex]
            mapped_entity = entity_instance.consolidate_and_map_data(Hash[ *entity_instance.class.connec_entities_names.collect{|name| name.parameterize('_').pluralize == entity_name ? [name, [entity]] : [ name, []]}.flatten(1) ], Hash[ *entity_instance.class.external_entities_names.collect{|name| [ name, []]}.flatten(1) ], organization, {})
          else
            mapped_entity = entity_instance.consolidate_and_map_data([entity], [], organization, {})
          end
          entity_instance.push_entities_to_external(external_client, mapped_entity[:connec_entities], organization)

          entity_instance.after_sync(connec_client, external_client, last_synchronization, organization, {})
        end
      end
    rescue => e
      Rails.logger.warn("error processing notification #{e.message} - #{e.backtrace.join("\n")}")
    end

    head 200, content_type: "application/json"
  end


  private
    def find_entity_instance(entity_name)
      Maestrano::Connector::Rails::Entity.entities_list.each do |entity_name_from_list|
        clazz = "Entities::#{entity_name_from_list.singularize.titleize.split.join}".constantize
        if clazz.methods.include?('connec_entities_names'.to_sym)
          return {instance: clazz.new, is_complex: true, name: entity_name_from_list} if clazz.connec_entities_names.map{|n| n.parameterize('_').pluralize}.include?(entity_name)
        elsif clazz.methods.include?('connec_entity_name'.to_sym)
          return {instance: clazz.new, is_complex: false, name: entity_name_from_list} if clazz.normalized_connec_entity_name == entity_name
        end
      end
      nil
    end
end
