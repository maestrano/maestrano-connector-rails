# frozen_string_literal: true

# Sidekiq Cron configuration
schedule_file = 'config/sidekiq_cron.yml'
Sidekiq::Cron::Job.load_from_hash! YAML.load_file(schedule_file) if File.exist?(schedule_file)
