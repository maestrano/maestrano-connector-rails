class Maestrano::Connector::Rails::Entity
  include Maestrano::Connector::Rails::Concerns::Entity

  # Return an array of all the entities that the connector can synchronize
  # If you add new entities, you need to generate
  # a migration to add them to existing organizations
  def self.entities_list
    %w(entity1 entity2)
  end
end