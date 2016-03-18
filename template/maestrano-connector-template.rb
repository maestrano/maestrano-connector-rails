def current_directory
  @current_directory ||=
      if __FILE__ =~ %r{\Ahttps?://}
        tempdir = Dir.mktmpdir("maestrano-connector-rails-")
        at_exit { FileUtils.remove_entry(tempdir) }
        git :clone => "--quiet https://github.com/maestrano/maestrano-connector-rails/ #{tempdir}"

        "#{tempdir}/template"
      else
        File.expand_path(File.dirname(__FILE__))
      end
end

# def current_directory
#   File.expand_path(File.dirname(__FILE__))
# end

# Add the current directory to the path Thor uses
# to look up files
def source_paths
  Array(super) + [current_directory]
end

#
# Rebuild the Gemfile from scratch
#
remove_file 'Gemfile'
run 'touch Gemfile'

add_source 'https://rubygems.org'

if yes?("Use JRuby? [y/n]")
  run 'echo "ruby \'2.2.3\', :engine => \'jruby\', :engine_version => \'9.0.5.0\'" | cat - Gemfile > temp && mv temp Gemfile'
  gem_group :production do
    gem 'activerecord-jdbcpostgresql-adapter'
  end
  gem_group :test, :develpment do
    gem 'activerecord-jdbcsqlite3-adapter'
  end
else
  gem 'sqlite3'
end

gem 'haml-rails'
gem 'bootstrap-sass'
gem 'autoprefixer-rails'

gem 'rails', '4.2.4'
gem 'turbolinks'
gem 'jquery-rails'
gem 'puma'
gem 'figaro'
gem 'tzinfo-data', platforms: [:mingw, :mswin, :jruby]
gem 'uglifier', '>= 1.3.0'

gem 'maestrano-connector-rails'


gem_group :test do
  gem 'simplecov'
  gem 'rspec-rails'
  gem 'factory_girl_rails'
  gem 'shoulda-matchers'
  gem 'timecop'
end

remove_file '.gitignore'
copy_file 'gitignore', '.gitignore'


#
# Cleanup
#
after_bundle do
  remove_dir 'app/mailers'
  remove_dir 'test'
  remove_file 'app/views/layouts/application.html.erb'
  remove_file 'app/assets/stylesheets/application.css'
  remove_file 'config/routes.rb'
  copy_file 'spec_helper.rb', 'spec/spec_helper.rb'
  copy_file 'factories.rb', 'spec/factories.rb'
  copy_file 'routes.rb', 'config/routes.rb'

  application do <<-RUBY
    config.generators do |g|
      g.test_framework :rspec, fixture: false
      g.view_specs false
      g.helper_specs false
    end
  RUBY
  end

  run 'bundle exec rails g connector:install'
  run 'bundle exec figaro install'
  run 'bundle exec rake railties:install:migrations'
  run 'bundle exec rake db:migrate'

  # Init repo and commit
  git :init
  git add: "."
  git commit: "-a -m 'Initial commit'"
end