class Maestrano::ConnecController < Maestrano::Rails::WebHookController
  def notifications
    begin
      params.except(:tenant, :controller, :action, :connec).each do |entity_name, entities|
        entity_class_hash = find_entity_class(entity_name)
        next Maestrano::Connector::Rails::ConnectorLogger.log('info', nil, "Received notification from Connec! for unknow entity: #{entity_name}") unless entity_class_hash

        entities.each do |entity|
          organization = Maestrano::Connector::Rails::Organization.find_by_uid_and_tenant(entity[:group_id], params[:tenant])

          begin
            if organization.nil?
              next Maestrano::Connector::Rails::ConnectorLogger.log('info', organization, "Received notification from Connec! for an unknown organization, organization_uid=\"#{entity[:group_id]}\", tenant=\"#{params[:tenant]}\"")
            end

            if organization.oauth_uid.blank?
              next Maestrano::Connector::Rails::ConnectorLogger.log('info', organization, "Received notification from Connec! for an organization not linked, organization_uid=\"#{entity[:group_id]}\", tenant=\"#{params[:tenant]}\"")
            end

            unless organization.sync_enabled && organization.synchronized_entities[entity_class_hash[:name].to_sym]
              next Maestrano::Connector::Rails::ConnectorLogger.log('info', organization, "Skipping notification from Connec! webhook, entity_name=\"#{entity_name}\"")
            end

            Maestrano::Connector::Rails::ConnectorLogger.log('info', organization, "Processing entity from Connec! webhook, entity_name=\"#{entity_name}\", data=\"#{entity}\"")

            connec_client = Maestrano::Connector::Rails::ConnecHelper.get_client(organization)
            external_client = Maestrano::Connector::Rails::External.get_client(organization)
            last_synchronization_date = organization.last_synchronization_date

            entity_instance = entity_class_hash[:class].new(organization, connec_client, external_client, {})
            entity_instance.before_sync(last_synchronization_date)

            # Build expected input for consolidate_and_map_data
            if entity_class_hash[:is_complex]
              connec_hash_of_entities = Maestrano::Connector::Rails::ComplexEntity.build_hash_with_entities(entity_instance.class.connec_entities_names, entity_name, ->(name) { name.parameterize('_').pluralize }, [entity])
              filtered_entities = entity_instance.filter_connec_entities(connec_hash_of_entities)

              empty_external_hash = Maestrano::Connector::Rails::ComplexEntity.build_empty_hash(entity_instance.class.external_entities_names)
              mapped_entity = entity_instance.consolidate_and_map_data(filtered_entities, empty_external_hash)
            else
              filtered_entities = entity_instance.filter_connec_entities([entity])
              mapped_entity = entity_instance.consolidate_and_map_data(filtered_entities, [])
            end
            entity_instance.push_entities_to_external(mapped_entity[:connec_entities])

            entity_instance.after_sync(last_synchronization_date)
          rescue => e
            Maestrano::Connector::Rails::ConnectorLogger.log('warn', organization, "error processing notification entity_name=\"#{entity_name}\", message=\"#{e.message}\", #{e.backtrace.join("\n")}")
          end
        end
      end
    rescue => e
      Maestrano::Connector::Rails::ConnectorLogger.log('warn', nil, "error processing notification #{e.message} - #{e.backtrace.join("\n")}")
    end

    head 200, content_type: 'application/json'
  end

  private

    def find_entity_class(entity_name)
      Maestrano::Connector::Rails::External.entities_list.each do |entity_name_from_list|
        clazz = "Entities::#{entity_name_from_list.singularize.titleize.split.join}".constantize
        if clazz.methods.include?('connec_entities_names'.to_sym)
          formatted_entities_names = clazz.connec_entities_names.map { |n| n.parameterize('_').pluralize }
          return {class: clazz, is_complex: true, name: entity_name_from_list} if formatted_entities_names.include?(entity_name)
        elsif clazz.methods.include?('connec_entity_name'.to_sym) && clazz.normalized_connec_entity_name == entity_name
          return {class: clazz, is_complex: false, name: entity_name_from_list}
        end
      end
      nil
    end
end
