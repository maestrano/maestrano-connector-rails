module Maestrano::Connector::Rails::Concerns::ConnecHelper
  extend ActiveSupport::Concern

  module ClassMethods
    def dependancies
      # Meant to be overloaded if needed
      {
        connec: '1.0',
        impac: '1.0',
        maestrano_hub: '1.0'
      }
    end

    def get_client(organization)
      client = Maestrano::Connec::Client[organization.tenant].new(organization.uid)
      client.class.headers('CONNEC-EXTERNAL-IDS' => 'true')
      client
    end

    # Returns a string of the tenant's current connec version.
    # Can use Gem::Version for version comparison
    def connec_version(organization)
      @@connec_version = Rails.cache.fetch("connec_version_#{organization.tenant}", namespace: 'maestrano', expires_in: 1.day) do
        response = get_client(organization).class.get("#{Maestrano[organization.tenant].param('connec.host')}/version", headers: {'Accept' => 'application/json'})
        response = JSON.parse(response.body)
        @@connec_version = response['ci_branch'].delete('v')
      end
      @@connec_version
    end

    def connec_version_lt?(version, organization)
      version = Gem::Version.new(version)
      current_version = Gem::Version.new(connec_version(organization))

      current_version < version
    rescue
      true
    end

    # Replaces the arrays of id received from Connec! by the id of the external application
    # Returns a hash {entity: {}, connec_id: '', id_refs_only_connec_entity: {}}
    # If an array has no id for this oauth_provider and oauth_uid but has one for connec, it returns a nil entity (skip the record)
    def unfold_references(connec_entity, references, organization)
      references = format_references(references)
      unfolded_connec_entity = connec_entity.deep_dup.with_indifferent_access
      not_nil = true

      # Id
      id_hash = unfolded_connec_entity['id'].find { |id| id['provider'] == organization.oauth_provider && id['realm'] == organization.oauth_uid }
      connec_id = unfolded_connec_entity['id'].find { |id| id['provider'] == 'connec' }['id']
      unfolded_connec_entity['id'] = id_hash ? id_hash['id'] : nil

      # Other references
      # Record references are references to other records (organization_id, item_id, ...)
      references[:record_references].each do |reference|
        not_nil &= unfold_references_helper(unfolded_connec_entity, reference.split('/'), organization)
      end
      # Id references are references to sub entities ids (invoice lines id, ...)
      # We do not return nil if we're missing an id reference
      references[:id_references].each do |reference|
        unfold_references_helper(unfolded_connec_entity, reference.split('/'), organization)
      end
      unfolded_connec_entity = not_nil ? unfolded_connec_entity : nil

      # Filter the connec entity to keep only the id_references fields (in order to save some memory)
      # Give an empty hash if there's nothing left
      id_refs_only_connec_entity = filter_connec_entity_for_id_refs(connec_entity, references[:id_references])

      {entity: unfolded_connec_entity, connec_id: connec_id, id_refs_only_connec_entity: id_refs_only_connec_entity}
    end

    # Replaces ids from the external application by arrays containing them
    def fold_references(mapped_external_entity, references, organization)
      references = format_references(references)
      mapped_external_entity = mapped_external_entity.with_indifferent_access

      # Use both record_references and id_references + the id
      (references.values.flatten + ['id']).each do |reference|
        fold_references_helper(mapped_external_entity, reference.split('/'), organization)
      end

      mapped_external_entity
    end

    # Builds an id_hash from the id and organization
    def id_hash(id, organization)
      {
        id: id,
        provider: organization.oauth_provider,
        realm: organization.oauth_uid
      }
    end

    # Recursive method for folding references
    def fold_references_helper(entity, array_of_refs, organization)
      ref = array_of_refs.shift
      field = entity[ref]
      return if field.blank?

      # Follow embedment path, remplace if it's not an array or a hash
      case field
      when Array
        field.each do |f|
          fold_references_helper(f, array_of_refs.dup, organization)
        end
      when Hash
        fold_references_helper(entity[ref], array_of_refs, organization)
      else
        id = field
        entity[ref] = [id_hash(id, organization)]
      end
    end

    # Recursive method for unfolding references
    def unfold_references_helper(entity, array_of_refs, organization)
      ref = array_of_refs.shift
      field = entity[ref]

      # Unfold the id
      if array_of_refs.empty? && field
        return entity.delete(ref) if field.is_a?(String) # ~retro-compatibility to ease transition aroud Connec! idmaps rework. Should be removed eventually.

        id_hash = field.find { |id| id[:provider] == organization.oauth_provider && id[:realm] == organization.oauth_uid }
        if id_hash
          entity[ref] = id_hash['id']
        elsif field.find { |id| id[:provider] == 'connec' } # Should always be true as ids will always contain a connec id
          # We may enqueue a fetch on the endpoint of the missing association, followed by a re-fetch on this one.
          # However it's expected to be an edge case, so for now we rely on the fact that the webhooks should be relativly in order.
          # Worst case it'll be done on following sync
          entity.delete(ref)
          return nil
        end
        true

      # Follow embedment path
      else
        return true if field.blank?

        case field
        when Array
          bool = true
          field.each do |f|
            bool &= unfold_references_helper(f, array_of_refs.dup, organization)
          end
          bool
        when Hash
          unfold_references_helper(entity[ref], array_of_refs, organization)
        end
      end
    end

    # Transforms the references into an hash {record_references: [], id_references: []}
    # References can either be an array (only record references), or a hash
    def format_references(references)
      return {record_references: references, id_references: []} if references.is_a?(Array)

      references[:record_references] ||= []
      references[:id_references] ||= []
      references
    end

    # Returns the connec_entity without all the fields that are not id_references
    def filter_connec_entity_for_id_refs(connec_entity, id_references)
      return {} if id_references.empty?

      entity = connec_entity.dup.with_indifferent_access
      tree = build_id_references_tree(id_references)

      filter_connec_entity_for_id_refs_helper(entity, tree)

      # TODO, improve performance by returning an empty hash if all the id_references have their id in the connec hash
      # We should still return all of them if at least one is missing as we are relying on the id
      entity
    end

    # Recursive method for filtering connec entities
    def filter_connec_entity_for_id_refs_helper(entity_hash, tree)
      return if tree.empty?

      entity_hash.slice!(*tree.keys)

      tree.each do |key, children|
        case entity_hash[key]
        when Array
          entity_hash[key].each do |hash|
            filter_connec_entity_for_id_refs_helper(hash, children)
          end
        when Hash
          filter_connec_entity_for_id_refs_helper(entity_hash[key], children)
        end
      end
    end

    # Builds a tree from an array of id_references
    # input: %w(lines/id lines/linked/id linked/id)
    # output: {"lines"=>{"id"=>{}, "linked"=>{"id"=>{}}}, "linked"=>{"id"=>{}}}
    def build_id_references_tree(id_references)
      tree = {}

      id_references.each do |id_reference|
        array_of_refs = id_reference.split('/')

        t = tree
        array_of_refs.each do |ref|
          t[ref] ||= {}
          t = t[ref]
        end
      end

      tree
    end

    # Merges the id arrays from two hashes while keeping only the id_references fields
    def merge_id_hashes(dist, src, id_references)
      dist = dist.with_indifferent_access
      src = src.with_indifferent_access

      id_references.each do |id_reference|
        array_of_refs = id_reference.split('/')

        merge_id_hashes_helper(dist, array_of_refs, src)
      end

      dist
    end

    # Recursive helper for merging id hashes
    def merge_id_hashes_helper(hash, array_of_refs, src, path = [])
      ref = array_of_refs.shift
      field = hash[ref]

      if array_of_refs.empty? && field
        value = value_from_hash(src, path + [ref])
        if value.is_a?(Array)
          hash[ref] = (field + value).uniq
        else
          hash.delete(ref)
        end
      else
        case field
        when Array
          field.each_with_index do |f, index|
            merge_id_hashes_helper(f, array_of_refs.dup, src, path + [ref, index])
          end
        when Hash
          merge_id_hashes_helper(field, array_of_refs, src, path + [ref])
        end
      end
    end

    # Returns the value from a hash following the given path
    # Path sould be an array like [:lines, 0, :id]
    def value_from_hash(hash, path)
      value = hash

      begin
        path.each do |p|
          value = value[p]
        end
        value
      rescue NoMethodError
        nil
      end
    end
  end
end
