module Maestrano::Connector::Rails::Concerns::External
  extend ActiveSupport::Concern

  module ClassMethods
    def get_client(organization)
      raise 'Not implemented'
    end

    def external_name
      raise 'Not implemented'
    end

    def get_id_from_entity_hash(entity)
      raise "Not implemented"
    end

    def get_last_update_date_from_entity_hash(entity)
      raise "Not implemented"
    end
  end
end