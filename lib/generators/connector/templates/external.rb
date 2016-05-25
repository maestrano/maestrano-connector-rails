class Maestrano::Connector::Rails::External
  include Maestrano::Connector::Rails::Concerns::External

  def self.external_name
    # TODO
    # Returns the name of the external app
  end

  def self.get_client(organization)
    # TODO
    # Returns a client for the external application for the given organization
    # e.g
    # SomeName.new :oauth_token => organization.oauth_token,
    # refresh_token: organization.refresh_token,
    # instance_url: organization.instance_url,
    # client_id: ENV[''],
    # client_secret: ENV['']
  end

  # Return an array of all the entities that the connector can synchronize
  # If you add new entities, you need to generate
  # a migration to add them to existing organizations
  def self.entities_list
    # TODO
    # The names in this list should match the names of your entities class
    # e.g %w(person, tasks_list)
    #  will synchronized Entities::Person and Entities::TasksList
    []
  end
end