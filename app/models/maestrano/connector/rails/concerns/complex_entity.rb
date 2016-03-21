module Maestrano::Connector::Rails::Concerns::ComplexEntity
  extend ActiveSupport::Concern

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
  def map_to_external_with_idmap(entity, organization, external_entity_name, sub_entity_instance)
    idmap = sub_entity_instance.class.find_idmap({connec_id: entity['id'], external_entity: external_entity_name, organization_id: organization.id})

    if idmap
      idmap.update(name: sub_entity_instance.class.object_name_from_connec_entity_hash(entity))
      if (!idmap.to_external) || idmap.last_push_to_external && idmap.last_push_to_external > entity['updated_at']
        Maestrano::Connector::Rails::ConnectorLogger.log('info', organization, "Discard Connec! #{sub_entity_instance.class.entity_name} : #{entity}")
        nil
      else
        {entity: sub_entity_instance.map_to(external_entity_name, entity, organization), idmap: idmap}
      end
    else
      {entity: sub_entity_instance.map_to(external_entity_name, entity, organization), idmap: sub_entity_instance.class.create_idmap_from_connec_entity(entity, external_entity_name, organization)}
    end
  end

  # -------------------------------------------------------------
  #          Entity equivalent methods
  # -------------------------------------------------------------
  def get_connec_entities(client, last_synchronization, organization, opts={})
    entities = ActiveSupport::HashWithIndifferentAccess.new

    self.class.connec_entities_names.each do |connec_entity_name|
      sub_entity_instance = "Entities::SubEntities::#{connec_entity_name.titleize.split.join}".constantize.new
      entities[connec_entity_name] = sub_entity_instance.get_connec_entities(client, last_synchronization, organization, opts)
    end
    entities
  end

  def get_external_entities(client, last_synchronization, organization, opts={})
    entities = ActiveSupport::HashWithIndifferentAccess.new

    self.class.external_entities_names.each do |external_entity_name|
      sub_entity_instance = "Entities::SubEntities::#{external_entity_name.titleize.split.join}".constantize.new
      entities[external_entity_name] = sub_entity_instance.get_external_entities(client, last_synchronization, organization, opts)
    end
    entities
  end

  def consolidate_and_map_data(connec_entities, external_entities, organization, opts={})
    modeled_external_entities = external_model_to_connec_model(external_entities)
    modeled_connec_entities = connec_model_to_external_model(connec_entities)

    modeled_external_entities.each do |external_entity_name, entities_in_connec_model|
      entities_in_connec_model.each do |connec_entity_name, entities|
        sub_entity_instance = "Entities::SubEntities::#{external_entity_name.titleize.split.join}".constantize.new

        entities.map!{|entity|
          idmap = sub_entity_instance.class.find_idmap(external_id: sub_entity_instance.class.id_from_external_entity_hash(entity), connec_entity: connec_entity_name, organization_id: organization.id)

          # No idmap: creating one, nothing else to do
          if idmap
            idmap.update(name: sub_entity_instance.class.object_name_from_external_entity_hash(entity))
          else
            next {entity: sub_entity_instance.map_to(connec_entity_name, entity, organization), idmap: sub_entity_instance.class.create_idmap_from_external_entity(entity, connec_entity_name, organization)}
          end

          # Not pushing entity to Connec!
          next nil unless idmap.to_connec

          # Entity has not been modified since its last push to connec!
          next nil if Maestrano::Connector::Rails::Entity.not_modified_since_last_push_to_connec?(idmap, entity, sub_entity_instance, organization)

          # Check for conflict with entities from connec!
          equivalent_connec_entities = modeled_connec_entities[connec_entity_name][external_entity_name] || []
          Maestrano::Connector::Rails::Entity.solve_conflict(entity, sub_entity_instance, equivalent_connec_entities, connec_entity_name, idmap, organization, opts)
        }.compact!
      end
    end

    modeled_connec_entities.each do |connec_entity_name, entities_in_external_model|
      entities_in_external_model.each do |external_entity_name, entities|
        sub_entity_instance = "Entities::SubEntities::#{connec_entity_name.titleize.split.join}".constantize.new
        entities.map!{|entity|
          self.map_to_external_with_idmap(entity, organization, external_entity_name, sub_entity_instance)
        }.compact!
      end
    end

    return {connec_entities: modeled_connec_entities, external_entities: modeled_external_entities}
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
  def push_entities_to_connec(connec_client, mapped_external_entities_with_idmaps, organization)
    mapped_external_entities_with_idmaps.each do |external_entity_name, entities_in_connec_model|
      sub_entity_instance = "Entities::SubEntities::#{external_entity_name.titleize.split.join}".constantize.new
      entities_in_connec_model.each do |connec_entity_name, mapped_entities_with_idmaps|
        sub_entity_instance.push_entities_to_connec_to(connec_client, mapped_entities_with_idmaps, connec_entity_name, organization)
      end
    end
  end


  def push_entities_to_external(external_client, mapped_connec_entities_with_idmaps, organization)
    mapped_connec_entities_with_idmaps.each do |connec_entity_name, entities_in_external_model|
      sub_entity_instance = "Entities::SubEntities::#{connec_entity_name.titleize.split.join}".constantize.new
      entities_in_external_model.each do |external_entity_name, mapped_entities_with_idmaps|
        sub_entity_instance.push_entities_to_external_to(external_client, mapped_entities_with_idmaps, external_entity_name, organization)
      end
    end
  end

  def before_sync(connec_client, external_client, last_synchronization, organization, opts)
    # Does nothing by default
  end

  def after_sync(connec_client, external_client, last_synchronization, organization, opts)
    # Does nothing by default
  end
end