module Maestrano::Connector::Rails
  class PushToConnecJob < ::ActiveJob::Base
    queue_as :default

    # expected hash: {"external_entity_name1" => [entity1, entity2], "external_entity_name2" => []}
    def perform(organization, entities_hash, opts={})
      return unless organization.sync_enabled && organization.oauth_uid

      connec_client = Maestrano::Connec::Client[organization.tenant].new(organization.uid)
      external_client = Maestrano::Connector::Rails::External.get_client(organization)
      last_synchronization = organization.last_successful_synchronization

      entities_hash.each do |external_entity_name, entities|
        if entity_instance_hash = find_entity_instance(external_entity_name)
          next unless organization.synchronized_entities[entity_instance_hash[:name].to_sym]

          entity_instance = entity_instance_hash[:instance]

          entity_instance.before_sync(connec_client, external_client, last_synchronization, organization, opts)
          # Build expected input for consolidate_and_map_data
          if entity_instance_hash[:is_complex]
            mapped_entities = entity_instance.consolidate_and_map_data(Hash[ *entity_instance.class.connec_entities_names.collect{|name| [ name, []]}.flatten(1) ], Hash[ *entity_instance.class.external_entities_names.collect{|name| name == external_entity_name ? [name, entities] : [ name, []]}.flatten(1) ], organization, {})
          else
            mapped_entities = entity_instance.consolidate_and_map_data([], entities, organization, {})
          end
          entity_instance.push_entities_to_connec(connec_client, mapped_entities[:external_entities], organization)

          entity_instance.after_sync(connec_client, external_client, last_synchronization, organization, opts)
        else
          Rails.logger.warn "Called push to connec job with unknow entity: #{external_entity_name}"
        end
      end
    end

    private
      def find_entity_instance(entity_name)
        Maestrano::Connector::Rails::Entity.entities_list.each do |entity_name_from_list|
          clazz = "Entities::#{entity_name_from_list.singularize.titleize.split.join}".constantize
          if clazz.methods.include?('external_entities_names'.to_sym)
            return {instance: clazz.new, is_complex: true, name: entity_name_from_list} if clazz.external_entities_names.include?(entity_name)
          elsif clazz.methods.include?('external_entity_name'.to_sym)
            return {instance: clazz.new, is_complex: false, name: entity_name_from_list} if clazz.external_entity_name == entity_name
          end
        end
        nil
      end
  end
end