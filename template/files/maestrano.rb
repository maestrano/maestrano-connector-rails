unless ENV['SKIP_CONFIGURATION']
  if Rails.env.test?
    Maestrano.configure { |config| config.environment = 'production' }
  else
    Maestrano.auto_configure
  end
end
