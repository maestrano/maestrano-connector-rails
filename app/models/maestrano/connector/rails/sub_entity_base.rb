module Maestrano::Connector::Rails
  class SubEntityBase < Entity

    def external?
      raise "Not implemented"
    end

    def entity_name
      raise "Not implemented"
    end

    def map_to(name, entity, organization)
      raise "Not implemented"
    end

    def external_entity_name
      if external?
        entity_name
      else
        raise "Forbidden call"
      end
    end

    def connec_entity_name
      if external?
        raise "Forbidden call"
      else
        entity_name
      end
    end

    def names_hash
      if external?
        {external_entity: entity_name.downcase}
      else
        {connec_entity: entity_name.downcase}
      end
    end

    def create_idmap_from_external_entity(entity, connec_entity_name, organization)
      if external?
        h = names_hash.merge({
          external_id: get_id_from_external_entity_hash(entity),
          name: object_name_from_external_entity_hash(entity),
          connec_entity: connec_entity_name.downcase,
          organization_id: organization.id
        })
        Maestrano::Connector::Rails::IdMap.create(h)
      else
        raise 'Forbidden call'
      end
    end

    def create_idmap_from_connec_entity(entity, external_entity_name, organization)
      if external?
        raise 'Forbidden call'
      else
        h = names_hash.merge({
          connec_id: entity['id'],
          name: object_name_from_connec_entity_hash(entity),
          external_entity: external_entity_name.downcase,
          organization_id: organization.id
        })
        Maestrano::Connector::Rails::IdMap.create(h)
      end
    end
  end
end