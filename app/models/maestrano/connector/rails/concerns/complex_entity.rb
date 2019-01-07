module Maestrano::Connector::Rails::Concerns::ComplexEntity
  extend ActiveSupport::Concern

  # -------------------------------------------------------------
  #                   Complex specific methods
  # Those methods needs to be implemented in each complex entity
  # -------------------------------------------------------------
  module ClassMethods
    def connec_entities_names
      raise 'Not implemented'
    end

    def external_entities_names
      raise 'Not implemented'
    end

    def formatted_external_entities_names
      formatted_entities_names(external_entities_names)
    end

    def formatted_connec_entities_names
      formatted_entities_names(connec_entities_names)
    end

    def formatted_entities_names(names)
      return names.with_indifferent_access if names.is_a?(Hash)

      names.index_by { |name| name }.with_indifferent_access
    end

    # For complex entities, we take the size of the biggest array
    # And the first record we can find (even if it's not in the first array)
    def count_and_first(entities)
      {count: entities.values.map(&:size).max, first: entities.values.flatten.first}
    end

    def public_connec_entity_name
      public_name(formatted_connec_entities_names)
    end

    def public_external_entity_name
      public_name(formatted_external_entities_names)
    end

    def public_name(formatted_names)
      names = formatted_names.keys.map(&:pluralize)
      return names.first.humanize if names.size == 1

      (names[0..-2].join(', ') + " and #{names.last}").humanize
    end

    def immutable?
      false
    end
  end

  # input :  {
  #             connec_entities_names[0]: [unmapped_connec_entity1, unmapped_connec_entity2],
  #             connec_entities_names[1]: [unmapped_connec_entity3, unmapped_connec_entity4]
  #          }
  # output : {
  #             connec_entities_names[0]: {
  #               external_entities_names[0]: [unmapped_connec_entity1, unmapped_connec_entity2]
  #             },
  #             connec_entities_names[1]: {
  #               external_entities_names[0]: [unmapped_connec_entity3],
  #               external_entities_names[1]: [unmapped_connec_entity4]
  #             }
  #          }
  def connec_model_to_external_model(connec_hash_of_entities)
    raise 'Not implemented'
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
    raise 'Not implemented'
  end

  # -------------------------------------------------------------
  #          Entity equivalent methods
  # -------------------------------------------------------------
  def get_connec_entities(last_synchronization_date = nil)
    entities = ActiveSupport::HashWithIndifferentAccess.new

    self.class.formatted_connec_entities_names.each do |connec_entity_name, connec_class_name|
      sub_entity_instance = instantiate_sub_entity_instance(connec_class_name)
      entities[connec_entity_name] = sub_entity_instance.get_connec_entities(last_synchronization_date)
    end
    entities
  end

  def get_external_entities_wrapper(last_synchronization_date = nil, entity_name = '')
    entities = ActiveSupport::HashWithIndifferentAccess.new

    self.class.formatted_external_entities_names.each do |external_entity_name, external_class_name|
      sub_entity_instance = instantiate_sub_entity_instance(external_class_name)
      entities[external_entity_name] = sub_entity_instance.get_external_entities_wrapper(last_synchronization_date, external_entity_name)
    end
    entities
  end

  def consolidate_and_map_data(connec_entities, external_entities)
    modelled_external_entities = external_model_to_connec_model(external_entities)
    modelled_connec_entities = connec_model_to_external_model(connec_entities)

    mapped_connec_entities = consolidate_and_map_connec_entities(modelled_connec_entities, modelled_external_entities)
    mapped_external_entities = consolidate_and_map_external_entities(modelled_external_entities)

    {connec_entities: mapped_connec_entities, external_entities: mapped_external_entities}
  end

  def consolidate_and_map_connec_entities(modelled_connec_entities, modelled_external_entities)
    modelled_connec_entities.each do |connec_entity_name, entities_in_external_model|
      entities_in_external_model.each do |external_entity_name, entities|
        sub_entity_instance = instantiate_sub_entity_instance(self.class.formatted_connec_entities_names[connec_entity_name])
        equivalent_external_entities = (modelled_external_entities[external_entity_name] && modelled_external_entities[external_entity_name][connec_entity_name]) || []

        entities_in_external_model[external_entity_name] = sub_entity_instance.consolidate_and_map_connec_entities(entities, equivalent_external_entities, sub_entity_instance.class.references[external_entity_name] || [], external_entity_name)
      end
    end
    modelled_connec_entities
  end

  def consolidate_and_map_external_entities(modelled_external_entities)
    modelled_external_entities.each do |external_entity_name, entities_in_connec_model|
      entities_in_connec_model.each do |connec_entity_name, entities|
        sub_entity_instance = instantiate_sub_entity_instance(self.class.formatted_external_entities_names[external_entity_name])

        entities_in_connec_model[connec_entity_name] = sub_entity_instance.consolidate_and_map_external_entities(entities, connec_entity_name)
      end
    end
    modelled_external_entities
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
      sub_entity_instance = instantiate_sub_entity_instance(self.class.formatted_external_entities_names[external_entity_name])
      entities_in_connec_model.each do |connec_entity_name, mapped_entities_with_idmaps|
        sub_entity_instance.push_entities_to_connec_to(mapped_entities_with_idmaps, connec_entity_name)
      end
    end
  end

  def push_entities_to_external(mapped_connec_entities_with_idmaps)
    mapped_connec_entities_with_idmaps.each do |connec_entity_name, entities_in_external_model|
      sub_entity_instance = instantiate_sub_entity_instance(self.class.formatted_connec_entities_names[connec_entity_name])
      entities_in_external_model.each do |external_entity_name, mapped_entities_with_idmaps|
        sub_entity_instance.push_entities_to_external_to(mapped_entities_with_idmaps, external_entity_name)
      end
    end
  end

  def instantiate_sub_entity_instance(entity_name)
    self.class.instantiate_sub_entity_instance(entity_name, @organization, @connec_client, @external_client, @opts)
  end

  # -------------------------------------------------------------
  #                      Helper methods
  # -------------------------------------------------------------
  module ClassMethods
    # output : {entities_names[0] => [], entities_names[1] => []}
    def build_empty_hash(entities_names)
      Hash[*entities_names.collect { |name| [name, []] }.flatten(1)]
    end

    # output: {entities_name[0] => [], entities_name[1] => entities}
    # with proc.call(entities_name[1] == entity_name)
    def build_hash_with_entities(entities_name, entity_name, proc, entities)
      Hash[*entities_name.collect { |name| proc.call(name) == entity_name ? [name, entities] : [name, []] }.flatten(1)]
    end

    def instantiate_sub_entity_instance(entity_name, organization, connec_client, external_client, opts)
      "Entities::SubEntities::#{entity_name.titleize.split.join}".constantize.new(organization, connec_client, external_client, opts)
    end

    def find_complex_entity_and_instantiate_external_sub_entity_instance(entity_name, organization, connec_client, external_client, opts)
      Maestrano::Connector::Rails::External.entities_list.each do |entity_name_from_list|
        clazz = "Entities::#{entity_name_from_list.singularize.titleize.split.join}".constantize
        if clazz.methods.include?('external_entities_names'.to_sym)
          formatted_names = clazz.formatted_external_entities_names
          return instantiate_sub_entity_instance(formatted_names[entity_name], organization, connec_client, external_client, opts) if formatted_names[entity_name]
        end
      end
      nil
    end
  end
end
