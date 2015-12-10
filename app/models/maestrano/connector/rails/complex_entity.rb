module Maestrano::Connector::Rails
  class ComplexEntity

    @@external_name = External.external_name

    # -------------------------------------------------------------
    #                   Complex specific methods
    # Those methods needs to be implemented in each complex entity
    # -------------------------------------------------------------
    def connec_entities_names
      raise "Not implemented"
    end

    def external_entities_names
      raise "Not implemented"
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
    def connec_model_to_external_model!(connec_hash_of_entities)
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
    def external_model_to_connec_model!(external_hash_of_entities)
      raise "Not implemented"
    end

    # -------------------------------------------------------------
    #          General methods
    # -------------------------------------------------------------
    def map_to_external_with_idmap(entity, organization, connec_entity_name, external_entity_name, sub_entity_instance)
      idmap = IdMap.find_by(connec_id: entity['id'], connec_entity: connec_entity_name.downcase, external_entity: external_entity_name.downcase, organization_id: organization.id)

      if idmap && idmap.last_push_to_external && idmap.last_push_to_external > entity['updated_at']
        ConnectorLogger.log('info', organization, "Discard Connec! #{connec_entity_name} : #{entity}")
        nil
      else
        {entity: sub_entity_instance.map_to(external_entity_name, entity, organization), idmap: idmap || IdMap.create(connec_id: entity['id'], connec_entity: connec_entity_name.downcase, external_entity: external_entity_name.downcase, organization_id: organization.id)}
      end
    end

    # -------------------------------------------------------------
    #          Entity equivalent methods
    # -------------------------------------------------------------
    def get_connec_entities(client, last_synchronization, organization, opts={})
      entities = ActiveSupport::HashWithIndifferentAccess.new

      self.connec_entities_names.each do |connec_entity_name|
        sub_entity_instance = "SubComplexEntities::#{connec_entity_name.titleize.split.join}".constantize.new
        entities[connec_entity_name] = sub_entity_instance.get_connec_entities(client, last_synchronization, organization, opts)
      end
      entities
    end

    def get_external_entities(client, last_synchronization, organization, opts={})
      entities = ActiveSupport::HashWithIndifferentAccess.new

      self.external_entities_names.each do |external_entity_name|
        sub_entity_instance = "SubComplexEntities::#{external_entity_name.titleize.split.join}".constantize.new
        entities[external_entity_name] = sub_entity_instance.get_external_entities(client, last_synchronization, organization, opts)
      end
      entities
    end

    def consolidate_and_map_data(connec_entities, external_entities, organization, opts)
      external_model_to_connec_model!(external_entities)
      connec_model_to_external_model!(connec_entities)

      external_entities.each do |external_entity_name, entities_in_connec_model|
        entities_in_connec_model.each do |connec_entity_name, entities|
          sub_entity_instance = "SubComplexEntities::#{external_entity_name.titleize.split.join}".constantize.new

          entities.map!{|entity|
            idmap = IdMap.find_by(external_id: sub_entity_instance.get_id_from_external_entity_hash(entity), external_entity: external_entity_name.downcase, connec_entity: connec_entity_name.downcase, organization_id: organization.id)

            # No idmap: creating one, nothing else to do
            unless idmap
              next {entity: sub_entity_instance.map_to(connec_entity_name, entity, organization), idmap: IdMap.create(external_id: sub_entity_instance.get_id_from_external_entity_hash(entity), external_entity: external_entity_name.downcase, connec_entity: connec_entity_name.downcase, organization_id: organization.id)}
            end

            # Entity has not been modified since its last push to connec!
            if idmap.last_push_to_connec && idmap.last_push_to_connec > sub_entity_instance.get_last_update_date_from_external_entity_hash(entity)
              ConnectorLogger.log('info', organization, "Discard #{@@external_name} #{external_entity_name} : #{entity}")
              next nil
            end

            equivalent_connec_entities = connec_entities[connec_entity_name][external_entity_name] || []
            # Check for conflict with entities from connec!
            if idmap.connec_id && connec_entity = equivalent_connec_entities.detect{|connec_entity| connec_entity['id'] == idmap.connec_id}
              # We keep the most recently updated entity
              if !opts[:connec_preemption].nil?
                keep_external = !opts[:connec_preemption]
              else
                keep_external = connec_entity['updated_at'] < sub_entity_instance.get_last_update_date_from_external_entity_hash(entity)
              end

              if keep_external
                ConnectorLogger.log('info', organization, "Conflict between #{@@external_name} #{external_entity_name} #{entity} and Connec! #{connec_entity_name} #{connec_entity}. Entity from #{@@external_name} kept")
                equivalent_connec_entities.delete(connec_entity)
                {entity: sub_entity_instance.map_to(connec_entity_name, entity, organization), idmap: idmap}
              else
                ConnectorLogger.log('info', organization, "Conflict between #{@@external_name} #{external_entity_name} #{entity} and Connec! #{connec_entity_name} #{connec_entity}. Entity from Connec! kept")
                nil
              end

            else
              {entity: sub_entity_instance.map_to(connec_entity_name, entity, organization), idmap: idmap}
            end
          }.compact!
        end
      end

      connec_entities.each do |connec_entity_name, entities_in_external_model|
        entities_in_external_model.each do |external_entity_name, entities|
          sub_entity_instance = "SubComplexEntities::#{connec_entity_name.titleize.split.join}".constantize.new
          entities.map!{|entity|
            self.map_to_external_with_idmap(entity, organization, connec_entity_name, external_entity_name, sub_entity_instance)
          }.compact!
        end
      end
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
        sub_entity_instance = "SubComplexEntities::#{external_entity_name.titleize.split.join}".constantize.new
        entities_in_connec_model.each do |connec_entity_name, mapped_entities_with_idmaps|
          sub_entity_instance.push_entities_to_connec_to(connec_client, mapped_entities_with_idmaps, connec_entity_name, organization)
        end
      end
    end


    def push_entities_to_external(external_client, mapped_connec_entities_with_idmaps, organization)
      mapped_connec_entities_with_idmaps.each do |connec_entity_name, entities_in_external_model|
        sub_entity_instance = "SubComplexEntities::#{connec_entity_name.titleize.split.join}".constantize.new
        entities_in_external_model.each do |external_entity_name, mapped_entities_with_idmaps|
          sub_entity_instance.push_entities_to_external_to(external_client, mapped_entities_with_idmaps, external_entity_name, organization)
        end
      end
    end
  end
end