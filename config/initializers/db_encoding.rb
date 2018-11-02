# frozen_string_literal: true

# Only applicable for MySQL
if ActiveRecord::Base.connection_config[:adapter] == 'mysql2'
  # Get the configured encoding
  configured_encoding = ActiveRecord::Base.connection_config[:encoding]

  # Get the actual character set from the DB
  database_charset = ActiveRecord::Base.connection.exec_query("SELECT @@character_set_database as charset").first['charset']

  msg = <<-LOG
WARNING: The configured db encoding `#{configured_encoding}` is different from the actual one `#{database_charset}`!
         This is likely to cause issues with special characters.
         Please see https://maestrano.atlassian.net/wiki/x/rQ0nBg or run:
           $ rails g connector:charset_migration
  LOG

  if configured_encoding != database_charset
    Rails.logger.warn msg
    warn msg
  end
end
