Retriable.configure do |c|
  c.contexts[:connec] = {
    on: [Net::OpenTimeout, Net::ReadTimeout, Net::HTTPGatewayTimeOut],
    on_retry: proc do |exception, try, elapsed_time, next_interval|
      Rails.logger.info "Connec! error - #{exception.class}: '#{exception.message}' - #{try} tries in #{elapsed_time} seconds and #{next_interval} seconds until the next try."
    end
  }
end
