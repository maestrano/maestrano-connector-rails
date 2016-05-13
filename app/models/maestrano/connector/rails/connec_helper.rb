module Maestrano::Connector::Rails
  class ConnecHelper
    
    # Replace the ids arrays by the external id
    # If a reference has no id for this oauth_provider and oauth_uid, does smart suff and respond nil
    def self.unfold_references(connec_entity, references, organization)
      return_nil = false

      id = connec_entity['id'].find{|id| id['provider'] == organization.oauth_provider && id['realm'] == organization.oauth_uid}
      if id
        connec_entity['id'] = id['id']
      else
        connec_entity[:__connec_id] = connec_entity['id'].find{|id| id['provider'] == 'connec'}['id']
        connec_entity['id'] = nil
      end

      references.each do |reference|
        if connec_entity[reference] && connec_entity[reference].kind_of?(Array) && !connec_entity[reference].empty?
          id = connec_entity[reference].find{|id| id['provider'] == organization.oauth_provider && id['realm'] == organization.oauth_uid}

          if id
            connec_entity[reference] = id['id']
          else
            return_nil = true
            # Do something smart
          end
        end
      end

      return_nil ? nil : connec_entity
    end

    def self.fold_references(mapped_external_entity, references, organization)
      (references + ['id']).each do |reference|
        reference = reference.to_sym
        unless mapped_external_entity[reference].blank?
          id = mapped_external_entity[reference]
          mapped_external_entity[reference] = [
            id_hash(id, organization)
          ]
        end
      end
      mapped_external_entity
    end

    def self.id_hash(id, organization)
      {
        id: id,
        provider: organization.oauth_provider,
        realm: organization.oauth_uid
      }
    end


  end
end