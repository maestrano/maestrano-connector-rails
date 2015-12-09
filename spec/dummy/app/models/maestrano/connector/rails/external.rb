class Maestrano::Connector::Rails::External
  include Maestrano::Connector::Rails::Concerns::External

  def self.external_name
    'Dummy app'
  end

  def self.get_client(organization)
    nil
  end
end