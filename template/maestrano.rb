Maestrano.auto_configure unless Rails.env.test?
Maestrano.configure { |config| config.environment = 'production' } if Rails.env.test?
