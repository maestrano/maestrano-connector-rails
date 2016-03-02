module Maestrano::Connector::Rails
  class PushToConnecJob < ::ActiveJob::Base
    queue_as :default

    # expected hash: {"external_entity_name1" => [entity1, entity2], "external_entity_name2" => []}
    def perform(organization, entities_hash)
      return unless organization.sync_enabled && organization.oauth_uid

      connec_client = Maestrano::Connec::Client.new(organization.uid)

      entities_hash.each do |external_entity_name, entities|
        if entity_instance_hash = find_entity_instance(external_entity_name)
          entity_instance = entity_instance_hash[:instance]
          next unless organization.synchronized_entities[entity_instance_hash[:name].to_sym]

          if entity_instance_hash[:is_complex]
            mapped_entities = entity_instance.consolidate_and_map_data(Hash[ *entity_instance.connec_entities_names.collect{|name| [ name, []]}.flatten(1) ], Hash[ *entity_instance.external_entities_names.collect{|name| name == external_entity_name.singularize ? [name, entities] : [ name, []]}.flatten(1) ], organization, {})
          else
            mapped_entities = entity_instance.consolidate_and_map_data([], entities, organization, {})
          end

          entity_instance.push_entities_to_connec(connec_client, mapped_entities[:external_entities], organization)
        else
          Rails.logger.warn "Called push to connec job with unknow entity: #{external_entity_name}"
        end
      end
    end

    private
      def find_entity_instance(entity_name)
        Maestrano::Connector::Rails::Entity.entities_list.each do |entity_name_from_list|
          instance = "Entities::#{entity_name_from_list.singularize.titleize.split.join}".constantize.new
          if instance.methods.include?('external_entities_names'.to_sym)
            return {instance: instance, is_complex: true, name: entity_name_from_list} if instance.external_entities_names.include?(entity_name)
          elsif instance.methods.include?('external_entity_name'.to_sym)
            return {instance: instance, is_complex: false, name: entity_name_from_list} if instance.external_entity_name == entity_name
          end
        end
        nil
      end
  end
end