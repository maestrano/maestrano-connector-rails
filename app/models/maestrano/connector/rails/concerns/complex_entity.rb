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
  #          Entity equivalent methods
  # -------------------------------------------------------------
  def get_connec_entities(last_synchronization)
    entities = ActiveSupport::HashWithIndifferentAccess.new

    self.class.connec_entities_names.each do |connec_entity_name|
      sub_entity_instance = instantiate_sub_entity_instance(connec_entity_name)
      entities[connec_entity_name] = sub_entity_instance.get_connec_entities(last_synchronization)
    end
    entities
  end

  def get_external_entities(last_synchronization)
    entities = ActiveSupport::HashWithIndifferentAccess.new

    self.class.external_entities_names.each do |external_entity_name|
      sub_entity_instance = instantiate_sub_entity_instance(external_entity_name)
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

        sub_entity_instance = instantiate_sub_entity_instance(connec_entity_name)
        equivalent_external_entities = (modeled_external_entities[external_entity_name] && modeled_external_entities[external_entity_name][connec_entity_name]) || []

        entities_in_external_model[external_entity_name] = sub_entity_instance.consolidate_and_map_connec_entities(entities, equivalent_external_entities, sub_entity_instance.class.references[external_entity_name] || [], external_entity_name)
      end
    end
    modeled_connec_entities
  end

  def consolidate_and_map_external_entities(modeled_external_entities)
    modeled_external_entities.each do |external_entity_name, entities_in_connec_model|
      entities_in_connec_model.each do |connec_entity_name, entities|
        sub_entity_instance = instantiate_sub_entity_instance(external_entity_name)

        entities_in_connec_model[connec_entity_name] = sub_entity_instance.consolidate_and_map_external_entities(entities, connec_entity_name)
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
      sub_entity_instance = instantiate_sub_entity_instance(external_entity_name)
      entities_in_connec_model.each do |connec_entity_name, mapped_entities_with_idmaps|
        sub_entity_instance.push_entities_to_connec_to(mapped_entities_with_idmaps, connec_entity_name)
      end
    end
  end


  def push_entities_to_external(mapped_connec_entities_with_idmaps)
    mapped_connec_entities_with_idmaps.each do |connec_entity_name, entities_in_external_model|
      sub_entity_instance = instantiate_sub_entity_instance(connec_entity_name)
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

  def instantiate_sub_entity_instance(entity_name)
    "Entities::SubEntities::#{entity_name.titleize.split.join}".constantize.new(@organization, @connec_client, @external_client, @opts)
  end

  # -------------------------------------------------------------
  #                      Helper methods
  # -------------------------------------------------------------
  module ClassMethods
    # output : {entities_names[0] => [], entities_names[1] => []}
    def build_empty_hash(entities_names)
      Hash[ *entities_names.collect{|name| [ name, []]}.flatten(1) ]
    end

    # output: {entities_name[0] => [], entities_name[1] => entities}
    # with proc.call(entities_name[1] == entity_name)
    def build_hash_with_entities(entities_name, entity_name, proc, entities)
      Hash[ *entities_name.collect{|name| proc.call(name) == entity_name ? [name, entities] : [ name, []]}.flatten(1) ]
    end
  end
end