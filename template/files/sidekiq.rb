# frozen_string_literal: true

# Ensure all jobs are removed before creating them
Sidekiq::Cron::Job.destroy_all!

# Schedule cron jobs at a random minute to avoid crowding of all connectors
minute = rand(60)
Sidekiq::Cron::Job.create(name: 'all_synchronizations_job', cron: "#{minute} * * * *", class: 'Maestrano::Connector::Rails::AllSynchronizationsJob')
Sidekiq::Cron::Job.create(name: 'update_configuration_job', cron: "#{minute} * * * *", class: 'Maestrano::Connector::Rails::UpdateConfigurationJob')
