module Maestrano::Connector::Rails
  class SubComplexEntityBase

    def external?
      raise "Not implemented"
    end

    def entity_name
      raise "Not implemented"
    end

    def map_to(name, entity)
      raise "Not implemented"
    end

    def set_mapper_organization(organization_id)
      self.mapper_class.set_organization(organization_id)
    end

    def create_idmap(entity, organization)
      if self.external?
        Maestrano::Connector::Rails::IdMap.create(
          external_id: Maestrano::Connector::Rails::External.get_id_from_entity_hash(entity),
          external_entity: self.entity_name.downcase,
          organization_id: organization.id
        )
      else
        Maestrano::Connector::Rails::IdMap.create(
          connec_id: entity['id'],
          connec_entity: self.entity_name.downcase,
          organization_id: organization.id
        )
      end
    end

  end
end