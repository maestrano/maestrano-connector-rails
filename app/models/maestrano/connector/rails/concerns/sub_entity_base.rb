module Maestrano::Connector::Rails::Concerns::SubEntityBase
  extend ActiveSupport::Concern

  module ClassMethods
    def external?
      raise "Not implemented"
    end

    def entity_name
      raise "Not implemented"
    end

    def external_entity_name
      if external?
        entity_name
      else
        raise "Forbidden call: cannot call external_entity_name for a connec entity"
      end
    end

    def connec_entity_name
      if external?
        raise "Forbidden call: cannot call connec_entity_name for an external entity"
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
          external_id: id_from_external_entity_hash(entity),
          name: object_name_from_external_entity_hash(entity),
          connec_entity: connec_entity_name.downcase,
          organization_id: organization.id
        })
        Maestrano::Connector::Rails::IdMap.create(h)
      else
        raise 'Forbidden call: cannot call create_idmap_from_external_entity for a connec entity'
      end
    end

    def create_idmap_from_connec_entity(entity, external_entity_name, organization)
      if external?
        raise 'Forbidden call: cannot call create_idmap_from_connec_entity for an external entity'
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

    # { 'External Entity'  => LalaMapper, 'Other external entity' => LiliMapper }
    # or { 'Connec Entity'  => LalaMapper, 'Other connec entity' => LiliMapper }
    def mapper_classes
      {}
    end

    # {
    #   'External Entity' => [{reference_class: Entities::.., connec_field: '', external_field: ''}],
    #   'Other external entity' => [{reference_class: Entities::.., connec_field: '', external_field: ''}]
    # }
    def references
      {}
    end
  end


  def map_to(name, entity, organization)
    mapper = self.class.mapper_classes[name]
    raise "Impossible mapping from #{self.class.entity_name} to #{name}" unless mapper

    ref_hash = {}
    if self.class.references[name]
      self.class.references[name].each do |ref|
        field = self.class.external? ? ref[:connec_field] : ref[:external_field]
        ref_hash.merge! field.split('/').reverse.inject(Maestrano::Connector::Rails::Entity.id_from_ref(entity, ref, self.class.external?, organization)) { |a, n| { n.to_sym => a } }
      end
    end

    if self.class.external?
      mapped_entity = mapper.denormalize(entity)
    else
      mapped_entity = mapper.normalize(entity)
    end
    mapped_entity.merge(ref_hash)
  end


  def map_external_entity_with_idmap(external_entity, connec_entity_name, idmap, organization)
    {entity: map_to(connec_entity_name, external_entity, organization), idmap: idmap}
  end
end