module Maestrano::Connector::Rails
  class ConnectorLogger

    def self.log(level, organization, msg)
      case level
      when 'info'
        Rails.logger.info "org: #{organization.uid} (#{organization.tenant}). Msg: #{msg}"
      when 'error'
        Rails.logger.error "org: #{organization.uid} (#{organization.tenant}). Msg: #{msg}"
      end
    end

  end
end