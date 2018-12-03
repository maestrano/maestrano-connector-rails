module Maestrano::Connector::Rails
  class HealthCheck
    # Check API connection with Connec!
    # any code that returns blank on success and non blank string upon failure
    def self.perform_connec_check
      if Maestrano::Api::OrganizationResource.first
        ''
      else
        'Connec!'
      end
    rescue => e
      "Connec!: #{e}. "
    end

    # Check API connection with Dev Platform!
    # any code that returns blank on success and non blank string upon failure
    def self.perform_dev_platform_check
      if Maestrano.auto_configure
        ''
      else
        'Dev Platform'
      end
    rescue => e
      "Dev Platform: #{e}. "
    end
  end
end
