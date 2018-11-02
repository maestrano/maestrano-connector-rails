# frozen_string_literal: true
class ConvertTablesToUtf8 < ActiveRecord::Migration
  def change_encoding(encoding,collation)
    # Allow for different adapter in different environment
    unless ActiveRecord::Base.connection_config[:adapter] == 'mysql2'
      say "Skipping conversion as non MySQL database (#{ActiveRecord::Base.connection_config[:adapter]})"
      return
    end
    tables = connection.tables
    dbname = ActiveRecord::Base.connection_config[:database]
    say_with_time "Converting database to #{encoding}" do
      execute <<-SQL
        ALTER DATABASE `#{dbname}` CHARACTER SET #{encoding} COLLATE #{collation};
      SQL
    end
    tables.each do |tablename|
      say_with_time "Converting table `#{tablename}` to #{encoding}" do
        execute <<-SQL
        ALTER TABLE `#{dbname}`.`#{tablename}` CONVERT TO CHARACTER SET #{encoding} COLLATE #{collation};
        SQL
      end
    end
  end

  def change
    reversible do |dir|
      dir.up do
        change_encoding('utf8','utf8_general_ci')
      end
      dir.down do
        change_encoding('latin1','latin1_swedish_ci')
      end
    end
  end
end
