module Maestrano::Connector::Rails::Concerns::ComplexEntity
  extend ActiveSupport::Concern

  def initialize(organization, connec_client, external_client, opts={})
    @organization = organization
    @connec_client = connec_client
    @external_client = external_client
    @opts = opts
  end

  # -------------------------------------------------------------
  #                   Complex specific methods
  # Those methods needs to be implemented in each complex entity
  # -------------------------------------------------------------
  module ClassMethods
    def connec_entities_names
      raise "Not implemented"
    end

    def external_entities_names
      raise "Not implemented"
    end
  end

  # input :  {
  #             connec_entities_names[0]: [unmapped_connec_entitiy1, unmapped_connec_entitiy2],
  #             connec_entities_names[1]: [unmapped_connec_entitiy3, unmapped_connec_entitiy4]
  #          }
  # output : {
  #             connec_entities_names[0]: {
  #               external_entities_names[0]: [unmapped_connec_entitiy1, unmapped_connec_entitiy2]
  #             },
  #             connec_entities_names[1]: {
  #               external_entities_names[0]: [unmapped_connec_entitiy3],
  #               external_entities_names[1]: [unmapped_connec_entitiy4]
  #             }
  #          }
  def connec_model_to_external_model(connec_hash_of_entities)
    raise "Not implemented"
  end

  # input :  {
  #             external_entities_names[0]: [unmapped_external_entity1}, unmapped_external_entity2],
  #             external_entities_names[1]: [unmapped_external_entity3}, unmapped_external_entity4]
  #          }
  # output : {
  #             external_entities_names[0]: {
  #               connec_entities_names[0]: [unmapped_external_entity1],
  #               connec_entities_names[1]: [unmapped_external_entity2]
  #             },
  #             external_entities_names[1]: {
  #               connec_entities_names[0]: [unmapped_external_entity3, unmapped_external_entity4]
  #             }
  #           }
  def external_model_to_connec_model(external_hash_of_entities)
    raise "Not implemented"
  end

  # -------------------------------------------------------------
  #          General methods
  # -------------------------------------------------------------
  # def map_to_external_with_idmap(entity, organization, external_entity_name, sub_entity_instance)
  #   idmap = sub_entity_instance.class.find_idmap({connec_id: entity['id'], external_entity: external_entity_name.downcase, organization_id: organization.id})

  #   if idmap
  #     return nil if idmap.external_inactive || !idmap.to_external

  #     if idmap.last_push_to_external && idmap.last_push_to_external > entity['updated_at']
  #       Maestrano::Connector::Rails::ConnectorLogger.log('info', organization, "Discard Connec! #{sub_entity_instance.class.entity_name} : #{entity}")
  #       nil
  #     else
  #       idmap.update(name: sub_entity_instance.class.object_name_from_connec_entity_hash(entity))
  #       {entity: sub_entity_instance.map_to(external_entity_name, entity, organization), idmap: idmap}
  #     end
  #   else
  #     {entity: sub_entity_instance.map_to(external_entity_name, entity, organization), idmap: sub_entity_instance.class.create_idmap_from_connec_entity(entity, external_entity_name, organization)}
  #   end
  # end

  # -------------------------------------------------------------
  #          Entity equivalent methods
  # -------------------------------------------------------------
  def get_connec_entities(last_synchronization)
    entities = ActiveSupport::HashWithIndifferentAccess.new

    self.class.connec_entities_names.each do |connec_entity_name|
      sub_entity_instance = "Entities::SubEntities::#{connec_entity_name.titleize.split.join}".constantize.new(@organization, @connec_client, @external_client, @opts)
      entities[connec_entity_name] = sub_entity_instance.get_connec_entities(last_synchronization)
    end
    entities
  end

  def get_external_entities(last_synchronization)
    entities = ActiveSupport::HashWithIndifferentAccess.new

    self.class.external_entities_names.each do |external_entity_name|
      sub_entity_instance = "Entities::SubEntities::#{external_entity_name.titleize.split.join}".constantize.new(@organization, @connec_client, @external_client, @opts)
      entities[external_entity_name] = sub_entity_instance.get_external_entities(last_synchronization)
    end
    entities
  end

  def consolidate_and_map_data(connec_entities, external_entities)
    modeled_external_entities = external_model_to_connec_model(external_entities)
    modeled_connec_entities = connec_model_to_external_model(connec_entities)

    mapped_connec_entities = consolidate_and_map_connec_entities(modeled_connec_entities, modeled_external_entities)
    mapped_external_entities = consolidate_and_map_external_entities(modeled_external_entities)

    return {connec_entities: mapped_connec_entities, external_entities: mapped_external_entities}
  end

  def consolidate_and_map_connec_entities(modeled_connec_entities, modeled_external_entities)
    modeled_connec_entities.each do |connec_entity_name, entities_in_external_model|
      entities_in_external_model.each do |external_entity_name, entities|
        sub_entity_instance = "Entities::SubEntities::#{connec_entity_name.titleize.split.join}".constantize.new(@organization, @connec_client, @external_client, @opts)
        equivalent_external_entities = (modeled_external_entities[external_entity_name] && modeled_external_entities[external_entity_name][connec_entity_name]) || []

        entities.map!{|entity|
          entity = Maestrano::Connector::Rails::ConnecHelper.unfold_references(entity, sub_entity_instance.class.references[external_entity_name] || [], @organization)
          next nil unless entity
          
          if entity['id'].blank?
            idmap = sub_entity_instance.class.create_idmap(organization_id: @organization.id, name: sub_entity_instance.class.object_name_from_connec_entity_hash(entity))
            next sub_entity_instance.map_connec_entity_with_idmap(entity, sub_entity_instance.class.external_entity_name, idmap)
          end

          idmap = sub_entity_instance.class.find_or_create_idmap(external_id: entity['id'], organization_id: @organization.id)
          idmap.update(name: sub_entity_instance.class.object_name_from_connec_entity_hash(entity))

          next nil if idmap.external_inactive || !idmap.to_external || sub_entity_instance.class.not_modified_since_last_push_to_external?(idmap, entity, sub_entity_instance, @organization)

          sub_entity_instance.class.solve_conflict(entity, sub_entity_instance, equivalent_external_entities, external_entity_name, idmap, @organization, @opts)
        }.compact!
      end
    end
    modeled_connec_entities
  end

  def consolidate_and_map_external_entities(modeled_external_entities)
    modeled_external_entities.each do |external_entity_name, entities_in_connec_model|
      entities_in_connec_model.each do |connec_entity_name, entities|
        sub_entity_instance = "Entities::SubEntities::#{external_entity_name.titleize.split.join}".constantize.new(@organization, @connec_client, @external_client, @opts)

        entities.map!{|entity|
          entity_id = sub_entity_instance.class.id_from_external_entity_hash(entity)
          idmap = sub_entity_instance.class.find_or_create_idmap({external_id: entity_id, organization_id: @organization.id})

          # Not pushing entity to Connec!
          next nil unless idmap.to_connec

          # Not pushing to Connec! and flagging as inactive if inactive in external application
          inactive = sub_entity_instance.class.inactive_from_external_entity_hash?(entity)
          idmap.update(external_inactive: inactive, name: sub_entity_instance.class.object_name_from_external_entity_hash(entity))
          next nil if inactive

          # Entity has not been modified since its last push to connec!
          next nil if sub_entity_instance.class.not_modified_since_last_push_to_connec?(idmap, entity, sub_entity_instance, @organization)

          {entity: sub_entity_instance.map_to(connec_entity_name, entity), idmap: idmap}
        }.compact!
      end
    end
    modeled_external_entities
  end

  # input : {
  #             external_entities_names[0]: {
  #               connec_entities_names[0]: [mapped_external_entity1],
  #               connec_entities_names[1]: [mapped_external_entity2]
  #             },
  #             external_entities_names[1]: {
  #               connec_entities_names[0]: [mapped_external_entity3, mapped_external_entity4]
  #             }
  #          }
  def push_entities_to_connec(mapped_external_entities_with_idmaps)
    mapped_external_entities_with_idmaps.each do |external_entity_name, entities_in_connec_model|
      sub_entity_instance = "Entities::SubEntities::#{external_entity_name.titleize.split.join}".constantize.new(@organization, @connec_client, @external_client, @opts)
      entities_in_connec_model.each do |connec_entity_name, mapped_entities_with_idmaps|
        sub_entity_instance.push_entities_to_connec_to(mapped_entities_with_idmaps, connec_entity_name)
      end
    end
  end


  def push_entities_to_external(mapped_connec_entities_with_idmaps)
    mapped_connec_entities_with_idmaps.each do |connec_entity_name, entities_in_external_model|
      sub_entity_instance = "Entities::SubEntities::#{connec_entity_name.titleize.split.join}".constantize.new(@organization, @connec_client, @external_client, @opts)
      entities_in_external_model.each do |external_entity_name, mapped_entities_with_idmaps|
        sub_entity_instance.push_entities_to_external_to(mapped_entities_with_idmaps, external_entity_name)
      end
    end
  end

  def before_sync(last_synchronization)
    # Does nothing by default
  end

  def after_sync(last_synchronization)
    # Does nothing by default
  end

  # This method is called during the webhook workflow only. It should return the hash of arrays of filtered entities
  # The aim is to have the same filtering as with the Connec! filters on API calls in the webhooks
  # input :  {
  #             external_entities_names[0]: [unmapped_external_entity1}, unmapped_external_entity2],
  #             external_entities_names[1]: [unmapped_external_entity3}, unmapped_external_entity4]
  #          }
  def filter_connec_entities(entities)
    entities
  end
end