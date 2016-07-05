module Maestrano::Connector::Rails::Concerns::EntityBase
  extend ActiveSupport::Concern

  def initialize(organization, connec_client, external_client, opts = {})
    @organization = organization
    @connec_client = connec_client
    @external_client = external_client
    @opts = opts
  end

  def opts_merge!(opts)
    @opts.merge!(opts)
  end

  def before_sync(last_synchronization_date)
    # Does nothing by default
  end

  def after_sync(last_synchronization_date)
    # Does nothing by default
  end

  # This method is called during the webhook workflow only. It should return the hash of arrays of filtered entities
  # The aim is to have the same filtering as with the Connec! filters on API calls in the webhooks
  # input :
  # For non complex entities [unmapped_external_entity1, unmapped_external_entity2]
  # For complex entities {
  #   external_entities_names[0]: [unmapped_external_entity1, unmapped_external_entity2],
  #   external_entities_names[1]: [unmapped_external_entity3, unmapped_external_entity4]
  # }
  def filter_connec_entities(entities)
    entities
  end
end
