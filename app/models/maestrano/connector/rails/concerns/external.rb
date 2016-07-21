module Maestrano::Connector::Rails::Concerns::External
  extend ActiveSupport::Concern

  module ClassMethods
    def get_client(organization)
      raise 'Not implemented'
    end

    def external_name
      raise 'Not implemented'
    end

    def create_account_link(organization = nil)
      raise 'Not implemented'
    end

    # Return an array of all the entities that the connector can synchronize
    # If you add new entities, you need to generate
    # a migration to add them to existing organizations
    def entities_list
      raise 'Not implemented'
    end
  end
end
