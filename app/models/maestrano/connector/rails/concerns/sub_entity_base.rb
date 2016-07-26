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
      mapper.normalize(entity).with_indifferent_access
    end
  end

  def map_connec_entity_with_idmap(connec_entity, external_entity_name, idmap, id_refs_only_connec_entity)
    {entity: map_to(external_entity_name, connec_entity), idmap: idmap, id_refs_only_connec_entity: id_refs_only_connec_entity}
  end

  def map_external_entity_with_idmap(external_entity, connec_entity_name, idmap)
    {entity: map_to(connec_entity_name, external_entity), idmap: idmap}
  end

  # Maps the entity received from external after a creation or an update and complete the received ids with the connec ones
  def map_and_complete_hash_with_connec_ids(external_hash, external_entity_name, connec_hash)
    return nil if connec_hash.empty?

    external_entity_instance = Maestrano::Connector::Rails::ComplexEntity.instantiate_sub_entity_instance(external_entity_name, @organization, @connec_client, @external_client, @opts)

    mapped_external_hash = external_entity_instance.map_to(self.class.connec_entity_name, external_hash)
    id_references = Maestrano::Connector::Rails::ConnecHelper.format_references(self.class.references[external_entity_name])

    Maestrano::Connector::Rails::ConnecHelper.merge_id_hashes(connec_hash, mapped_external_hash, id_references[:id_references])
  end
end
