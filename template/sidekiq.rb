Sidekiq::Cron::Job.create(name: 'AllSynchronizationsJob runs every hour', cron: '0 * * * *', class: 'Maestrano::Connector::Rails::AllSynchronizationsJob')
