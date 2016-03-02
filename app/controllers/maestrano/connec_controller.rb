class Maestrano::ConnecController < Maestrano::Rails::WebHookController

  def notifications
    Rails.logger.debug "Received notification from Connec!: #{params}"

    begin
      params.except(:tenant, :controller, :action).each do |entity_name, entities|
        if entity_instance_hash = find_entity_instance(entity_name)
          entity_instance = entity_instance_hash[:instance]

          entities.each do |entity|
            if (organization = Maestrano::Connector::Rails::Organization.find_by(uid: entity[:group_id], tenant: params[:tenant])) && organization.oauth_uid
              Maestrano::Connector::Rails::ConnectorLogger.log('info', organization, "Received entity from Connec! webhook: Entity=#{entity_name}, Data=#{entity}")
              if organization.sync_enabled && organization.synchronized_entities[entity_instance_hash[:name].to_sym]
                external_client = Maestrano::Connector::Rails::External.get_client(organization)

                # Build expected input for consolidate_and_map_data
                if entity_instance_hash[:is_complex]
                  mapped_entity = entity_instance.consolidate_and_map_data(Hash[ *entity_instance.connec_entities_names.collect{|name| name.downcase.pluralize == entity_name ? [name, [entity]] : [ name, []]}.flatten(1) ], Hash[ *entity_instance.external_entities_names.collect{|name| [ name, []]}.flatten(1) ], organization, {})
                else
                  mapped_entity = entity_instance.consolidate_and_map_data([entity], [], organization, {})
                end

                entity_instance.push_entities_to_external(external_client, mapped_entity[:connec_entities], organization)
              end

            else
              Rails.logger.warn "Received notification from Connec! for unknown group or group without oauth: #{entity['group_id']} (tenant: #{params[:tenant]})"
            end
          end
        else
          Rails.logger.info "Received notification from Connec! for unknow entity: #{entity_name}"
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
        instance = "Entities::#{entity_name_from_list.singularize.titleize.split.join}".constantize.new
        if instance.methods.include?('connec_entities_names'.to_sym)
          return {instance: instance, is_complex: true, name: entity_name_from_list} if instance.connec_entities_names.map{|n| n.pluralize.downcase}.include?(entity_name)
        elsif instance.methods.include?('connec_entity_name'.to_sym)
          return {instance: instance, is_complex: false, name: entity_name_from_list} if instance.normalized_connec_entity_name == entity_name
        end
      end
      nil
    end
end
