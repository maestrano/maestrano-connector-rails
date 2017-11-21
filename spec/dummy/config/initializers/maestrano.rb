if Rails.env.test?
  Maestrano.configure do |config|
    config.environment = 'production'
    config.api.id = 'api_id'
    config.api.key = 'api_key'
  end
else
  Maestrano.auto_configure
end
