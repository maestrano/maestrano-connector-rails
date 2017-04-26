module Maestrano::Connector::Rails::Concerns::ConnectorLogger
  extend ActiveSupport::Concern

  module ClassMethods
    def log(level, organization, msg, params = {})
      line = "uid=\"#{organization&.uid}\", org_uid=\"#{organization&.org_uid}\", tenant=\"#{organization&.tenant}\""
      line = "#{line}, #{params.map { |k, v| "#{k}=\"#{v}\"" }.join(', ')}" if params.present?
      Rails.logger.method(level).call("#{line}, message=\"#{msg}\"")
    end
  end
end
