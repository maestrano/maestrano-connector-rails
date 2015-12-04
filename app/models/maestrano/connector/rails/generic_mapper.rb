module Maestrano::Connector::Rails
  class GenericMapper

    def self.set_organization(organization_id)
      @@organization_id = organization_id
    end
  end
end