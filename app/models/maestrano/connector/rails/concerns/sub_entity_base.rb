module Maestrano::Connector::Rails::Concerns::SubEntityBase
  extend ActiveSupport::Concern

  module ClassMethods
    def external?
      raise 'Not implemented'
    end

    def entity_name
      raise 'Not implemented'
    end

    def external_entity_name
      return entity_name if external?
      raise 'Forbidden call: cannot call external_entity_name for a connec entity'
    end

    def connec_entity_name
      return entity_name unless external?
      raise 'Forbidden call: cannot call connec_entity_name for an external entity'
    end

    def names_hash
      if external?
        {external_entity: entity_name.downcase}
      else
        {connec_entity: entity_name.downcase}
      end
    end

    # { 'External Entity'  => LalaMapper, 'Other external entity' => LiliMapper }
    # or { 'Connec Entity'  => LalaMapper, 'Other connec entity' => LiliMapper }
    def mapper_classes
      {}
    end

    # {
    #   'External Entity' => ['organization_id'],
    #   'Other external entity' => ['an array of the connec reference fields']
    # }
    def references
      {}
    end
  end

  def map_to(name, entity)
    mapper = self.class.mapper_classes[name]
    raise "Impossible mapping from #{self.class.entity_name} to #{name}" unless mapper

    if self.class.external?
      mapped_entity = mapper.denormalize(entity).merge(id: self.class.id_from_external_entity_hash(entity))
      folded_entity = Maestrano::Connector::Rails::ConnecHelper.fold_references(mapped_entity, self.class.references[name] || [], @organization)

      if self.class.connec_matching_fields
        folded_entity[:opts] ||= {}
        folded_entity[:opts][:matching_fields] = self.class.connec_matching_fields
      end

      folded_entity
    else
      connec_id = entity[:__connec_id]
      mapped_entity = mapper.normalize(entity)
      (connec_id ? mapped_entity.merge(__connec_id: connec_id) : mapped_entity).with_indifferent_access
    end
  end

  def map_connec_entity_with_idmap(connec_entity, external_entity_name, idmap)
    {entity: map_to(external_entity_name, connec_entity), idmap: idmap}
  end

  def map_external_entity_with_idmap(external_entity, connec_entity_name, idmap)
    {entity: map_to(connec_entity_name, external_entity), idmap: idmap}
  end
end
