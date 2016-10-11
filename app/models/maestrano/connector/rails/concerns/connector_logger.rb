module Maestrano::Connector::Rails::Concerns::ConnectorLogger
  extend ActiveSupport::Concern

  module ClassMethods
    def log(level, organization, msg)
      Rails.logger.method(level).call("organization_uid=\"#{organization&.uid}\", tenant=\"#{organization&.tenant}\"), message=\"#{msg}\"")
    end
  end
end
