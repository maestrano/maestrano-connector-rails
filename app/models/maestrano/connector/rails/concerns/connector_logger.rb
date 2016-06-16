module Maestrano::Connector::Rails::Concerns::ConnectorLogger
  extend ActiveSupport::Concern

  module ClassMethods
    def log(level, organization, msg)
      Rails.logger.method(level).call("org: #{organization.uid} (#{organization.tenant}). Msg: #{msg}")
    end
  end
end
