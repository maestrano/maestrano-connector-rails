module Maestrano::Connector::Rails::Concerns::ConnectorLogger
  extend ActiveSupport::Concern

  module ClassMethods
    def log(level, organization, msg)
      Rails.logger.method(level).call("uid=#{organization&.uid}, org_uid= #{organization&.org_uid} , tenant=#{organization&.tenant}): #{msg}")
    end
  end
end
