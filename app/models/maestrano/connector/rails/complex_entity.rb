module Maestrano::Connector::Rails
  class ComplexEntity

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
    #             connec_entity_names[0]: [unmapped_connec_entitiy1, unmapped_connec_entitiy2],
    #             connec_entity_names[1]: [unmapped_connec_entitiy3, unmapped_connec_entitiy4]
    #          }
    # output : {
    #             connec_entity_names[0]: {
    #               external_entities_names[0]: [unmapped_connec_entitiy1, unmapped_connec_entitiy2]
    #             },
    #             connec_entity_names[1]: {
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
    #               connec_entity_names[0]: [unmapped_external_entity1],
    #               connec_entity_names[1]: [unmapped_external_entity2]
    #             },
    #             external_entities_names[1]: {
    #               connec_entity_names[0]: [unmapped_external_entity3, unmapped_external_entity4]
    #             }
    #           }
    def external_model_to_connec_model!(external_hash_of_entities)
      raise "Not implemented"
    end

    # -------------------------------------------------------------
    #          General methods
    # -------------------------------------------------------------
    def set_mapper_organization(organization_id)
      (self.connec_entities_names + self.external_entities_names).each do |name|
        "SubComplexEntities::#{name.titleize.split.join}".constantize.new.set_mapper_organization(organization_id)
      end
    end

    def unset_mapper_organization
      (self.connec_entities_names + self.external_entities_names).each do |name|
        "SubComplexEntities::#{name.titleize.split.join}".constantize.new.set_mapper_organization(nil)
      end
    end

    def self.map_to_external_with_idmap(entity, organization, connec_entity_name, external_entity_name, sub_entity_instance)
      idmap = Maestrano::Connector::Rails::IdMap.find_by(connec_id: entity['id'], connec_entity: connec_entity_name.downcase, organization_id: organization.id)

      if idmap && idmap.last_push_to_external && idmap.last_push_to_external > entity['updated_at']
        Rails.logger.info "Discard Connec! #{connec_entity_name} : #{entity}"
        nil
      else
        {entity: sub_entity_instance.map_to(external_entity_name, entity), idmap: idmap || sub_entity_instance.create_idmap(entity, organization)}
      end
    end

    # -------------------------------------------------------------
    #          Overwritten methods
    # -------------------------------------------------------------
    def get_connec_entities(client, last_synchronization, opts={})
      entities = ActiveSupport::HashWithIndifferentAccess.new

      self.connec_entity_names.each do |connec_entity_name|
        sub_entity_instance = "SubComplexEntities::#{connec_entity_name.titleize.split.join}".constantize.new
        entities[connec_entity_name] = sub_entity_instance.get_connec_entities(client, last_synchronization, opts)
      end
    end

    def get_external_entities(client, last_synchronization, opts={})
      entities = ActiveSupport::HashWithIndifferentAccess.new

      self.external_entities_names.each do |external_entity_name|
        sub_entity_instance = "SubComplexEntities::#{external_entity_name.titleize.split.join}".constantize.new
        entities[external_entity_name] = sub_entity_instance.get_external_entities(client, last_synchronization, opts)
      end
    end

    def consolidate_and_map_data(connec_entities, external_entities, organization)
      external_model_to_connec_model!(external_entities)
      connec_model_to_external_model!(connec_entities)

      external_entities.each do |external_entity_name, entities_in_connec_model|
        entities_in_connec_model.each do |connec_entity_name, entities|
          sub_entity_instance = "SubComplexEntities::#{external_entity_name.titleize.split.join}".constantize.new

          entities.map!{|entity|
            idmap = IdMap.find_by(external_id: sub_entity_instance.get_id_from_external_entity_hash(entity), external_entity: external_entity_name.downcase, organization_id: organization.id)

            # No idmap: creating one, nothing else to do
            unless idmap
              next {entity: sub_entity_instance.map_to(connec_entity_name, entity), idmap: sub_entity_instance.create_idmap(entity, organization)}
            end

            # Entity has not been modified since its last push to connec!
            if idmap.last_push_to_connec && idmap.last_push_to_connec > sub_entity_instance.get_last_update_date_from_external_entity_hash(entity)
              Rails.logger.info "Discard #{@@external_name} #{external_entity_name} : #{entity}"
              next nil
            end

            equivalent_connec_entities = connec_entities[connec_entity_name][external_entity_name] || []
            # Check for conflict with entities from connec!
            self.solve_conflicts(idmap, equivalent_connec_entities, entity)
          }.compact!
        end
      end

      connec_entities.each do |connec_entity_name, entities_in_external_model|
        entities_in_external_model.each do |external_entity_name, entities|
          sub_entity_instance = "SubComplexEntities::#{connec_entity_name.titleize.split.join}".constantize.new
          entities.map!{|entity|
            ComplexEntity.map_to_external_with_idmap(entity, organization, connec_entity_name, external_entity_name, sub_entity_instance)
          }.compact!
        end
      end
    end

    # input : {
    #             external_entities_names[0]: {
    #               connec_entity_names[0]: [mapped_external_entity1],
    #               connec_entity_names[1]: [mapped_external_entity2]
    #             },
    #             external_entities_names[1]: {
    #               connec_entity_names[0]: [mapped_external_entity3, mapped_external_entity4]
    #             }
    #          }
    def push_entities_to_connec(connec_client, mapped_external_entities_with_idmaps)
      mapped_external_entities_with_idmaps.each do |external_entity_name, entities_in_connec_model|
        entities_in_connec_model.each do |connec_entity_name, mapped_entities_with_idmaps|
          sub_entity_instance = "SubComplexEntities::#{connec_entity_name.titleize.split.join}".constantize.new
          sub_entity_instance.push_entities_to_connec(connec_client, mapped_entities_with_idmaps)
        end
      end
    end


    def push_entities_to_external(external_client, mapped_connec_entities_with_idmaps)
      mapped_connec_entities_with_idmaps.each do |connec_entity_name, entities_in_external_model|
        entities_in_external_model.each do |external_entity_name, mapped_entities_with_idmaps|
          sub_entity_instance = "SubComplexEntities::#{external_entity_name.titleize.split.join}".constantize.new
          sub_entity_instance.push_entities_to_external(external_client, mapped_entities_with_idmaps)
        end
      end
    end
  end