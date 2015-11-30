module Maestrano::Connector::Rails::Concerns::ComplexEntity
  extend ActiveSupport::Concern

  # ----------------------------------------------
  #          Complex specific methods
  # ----------------------------------------------
  def connec_to_external
    raise "Not implemented"
  end

  def external_to_connec
    raise "Not implemented"
  end

  def connec_entities_names
    raise "Not implemented"
  end

  def external_entities_names
    raise "Not implemented"
  end

  # set_mapper_organization

  def get_connec_entities(client, last_synchronization, opts={})
    entities = ActiveSupport::HashWithIndifferentAccess.new

    self.external_entities_names.each do |entity_name|
      entities[entity_name] = get_connec_entities_by_name(client, last_synchronization, entity_name, opts)
    end
  end

  def get_external_entities(client, last_synchronization, opts={})
    entities = ActiveSupport::HashWithIndifferentAccess.new

    self.external_entities_names.each do |entity_name|
      entities[entity_name] = get_external_entities_by_name(client, last_synchronization, entity_name, opts)
    end
  end



end