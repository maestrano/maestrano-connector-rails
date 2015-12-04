module Maestrano::Connector::Rails
  class SubComplexEntityBase < Entity

    def external?
      raise "Not implemented"
    end

    def entity_name
      raise "Not implemented"
    end

    def mapper_classes
      raise "Not implemented"
    end

    def map_to(name, entity)
      raise "Not implemented"
    end

    def external_entity_name
      if self.external?
        self.entity_name
      else
        raise "Forbidden call"
      end
    end

    def connec_entity_name
      if self.external?
        raise "Forbidden call"
      else
        self.entity_name
      end
    end

    def set_mappers_organization(organization_id)
      self.mapper_classes.each do |klass|
        klass.set_organization(organization_id)
      end
    end

    def create_idmap(entity, organization)
      if self.external?
        Maestrano::Connector::Rails::IdMap.create(
          external_id: self.get_id_from_external_entity_hash(entity),
          external_entity: self.external_entity_name.downcase,
          organization_id: organization.id
        )
      else
        Maestrano::Connector::Rails::IdMap.create(
          connec_id: entity['id'],
          connec_entity: self.connec_entity_name.downcase,
          organization_id: organization.id
        )
      end
    end

  end
end