unless ENV['SKIP_CONFIGURATION']
  begin
    if Rails.env.test?
      Maestrano.configure { |config| config.environment = 'production' }
    else
      Maestrano.auto_configure
    end
  rescue StandardError => e
    puts "Cannot load configuration #{e.message}"
  end
end
