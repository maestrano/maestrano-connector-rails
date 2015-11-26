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
end