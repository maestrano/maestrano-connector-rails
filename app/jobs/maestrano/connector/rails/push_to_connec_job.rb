module Maestrano::Connector::Rails
  class PushToConnecJob < ::ActiveJob::Base
    queue_as :default

    # expected hash: {"external_entity_name1" => [entity1, entity2], "external_entity_name2" => []}
    def perform(organization, entities_hash, opts = {})
      return unless organization.sync_enabled && organization.oauth_uid

      connec_client = Maestrano::Connector::Rails::ConnecHelper.get_client(organization)
      external_client = Maestrano::Connector::Rails::External.get_client(organization)
      last_synchronization_date = organization.last_synchronization_date

      entities_hash.each do |external_entity_name, entities|
        if entity_instance_hash = find_entity_instance(external_entity_name, organization, connec_client, external_client, opts)
          next unless organization.synchronized_entities[entity_instance_hash[:name].to_sym]

          entity_instance = entity_instance_hash[:instance]

          entity_instance.before_sync(last_synchronization_date)
          # Build expected input for consolidate_and_map_data
          mapped_entities = if entity_instance_hash[:is_complex]
                              entity_instance.consolidate_and_map_data(ComplexEntity.build_empty_hash(entity_instance.class.connec_entities_names), ComplexEntity.build_hash_with_entities(entity_instance.class.external_entities_names, external_entity_name, ->(name) { name }, entities))
                            else
                              entity_instance.consolidate_and_map_data([], entities)
                            end
          entity_instance.push_entities_to_connec(mapped_entities[:external_entities])

          entity_instance.after_sync(last_synchronization_date)
        else
          Rails.logger.warn "Called push to connec job with unknow entity: #{external_entity_name}"
        end
      end
    end

    private

      def find_entity_instance(entity_name, organization, connec_client, external_client, opts)
        Maestrano::Connector::Rails::External.entities_list.each do |entity_name_from_list|
          clazz = "Entities::#{entity_name_from_list.singularize.titleize.split.join}".constantize
          if clazz.methods.include?('external_entities_names'.to_sym)
            return {instance: clazz.new(organization, connec_client, external_client, opts), is_complex: true, name: entity_name_from_list} if clazz.external_entities_names.include?(entity_name)
          elsif clazz.methods.include?('external_entity_name'.to_sym)
            return {instance: clazz.new(organization, connec_client, external_client, opts), is_complex: false, name: entity_name_from_list} if clazz.external_entity_name == entity_name
          end
        end
        nil
      end
  end
end
