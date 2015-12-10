module Maestrano::Connector::Rails
  class ConnectorLogger

    def self.log(level, organization, msg)
      Rails.logger.method(level).call("org: #{organization.uid} (#{organization.tenant}). Msg: #{msg}")
    end

  end
end