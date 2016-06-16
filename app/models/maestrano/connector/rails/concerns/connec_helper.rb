module Maestrano::Connector::Rails::Concerns::ConnecHelper
  extend ActiveSupport::Concern

  module ClassMethods

    def get_client(organization)
      client = Maestrano::Connec::Client[organization.tenant].new(organization.uid)
      client.class.headers('CONNEC-EXTERNAL-IDS' => 'true')
      client
    end
    
    # Replace the ids arrays by the external id
    # If a reference has no id for this oauth_provider and oauth_uid but has one for connec returns nil
    def unfold_references(connec_entity, references, organization)
      unfolded_connec_entity = connec_entity.with_indifferent_access
      not_nil = true

      # Id
      id = unfolded_connec_entity['id'].find{|id| id['provider'] == organization.oauth_provider && id['realm'] == organization.oauth_uid}
      unfolded_connec_entity[:__connec_id] = unfolded_connec_entity['id'].find{|id| id['provider'] == 'connec'}['id']
      if id
        unfolded_connec_entity['id'] = id['id']
      else
        unfolded_connec_entity['id'] = nil
      end

      # Other refs
      references.each do |reference|
        not_nil &&= unfold_references_helper(unfolded_connec_entity, reference.split('/'), organization)
      end
      not_nil ? unfolded_connec_entity : nil
    end

    def fold_references(mapped_external_entity, references, organization)
      mapped_external_entity = mapped_external_entity.with_indifferent_access
      (references + ['id']).each do |reference|
        fold_references_helper(mapped_external_entity, reference.split('/'), organization)
      end
      mapped_external_entity
    end

    def id_hash(id, organization)
      {
        id: id,
        provider: organization.oauth_provider,
        realm: organization.oauth_uid
      }
    end

    def fold_references_helper(entity, array_of_refs, organization)
      ref = array_of_refs.shift
      field = entity[ref]

      # Follow embedment path, remplace if it's not an array or a hash
      unless field.blank?
        case field
        when Array
          field.each do |f|
            fold_references_helper(f, array_of_refs.dup, organization)
          end
        when HashWithIndifferentAccess
          fold_references_helper(entity[ref], array_of_refs, organization)
        else
          id = field
          entity[ref] = [id_hash(id, organization)]
        end
      end
    end

    def unfold_references_helper(entity, array_of_refs, organization)
      ref = array_of_refs.shift
      field = entity[ref]

      # Unfold the id
      if array_of_refs.empty?
        if id = field && field.find{|id| id[:provider] == organization.oauth_provider && id[:realm] == organization.oauth_uid}
          entity[ref] = id['id']
        elsif field && field.find{|id| id[:provider] == 'connec'}
          # We may enqueue a fetch on the endpoint of the missing association, followed by a re-fetch on this one.
          # However it's expected to be an edge case, so for now we rely on the fact that the webhooks should be relativly in order.
          # Worst case it'll be done on following sync
          return nil
        end

      # Follow embedment path
      else
        unless field.blank?
          case field
          when Array
            field.each do |f|
              unfold_references_helper(f, array_of_refs.dup, organization)
            end
          when HashWithIndifferentAccess
            unfold_references_helper(entity[ref], array_of_refs, organization)
          end
        end
      end
      true
    end

  end
end