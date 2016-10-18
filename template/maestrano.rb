Maestrano.auto_configure unless Rails.env.test?
Maestrano.configure { |config| config.environment = 'test' } if Rails.env.test?
