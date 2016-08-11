require 'sidekiq/web'

Sidekiq::Cron::Job.create(name: 'AllSynchronizationsJob runs every hour', cron: '0 * * * *', class: 'Maestrano::Connector::Rails::AllSynchronizationsJob')

# Sidekiq Admin
Sidekiq::Web.use Rack::Auth::Basic do |username, password|
  username == ENV['SIDEKIQ_USERNAME'] && password == ENV['SIDEKIQ_PASSWORD']
end
