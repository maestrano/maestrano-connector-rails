def current_directory
  @current_directory ||=
      if __FILE__ =~ %r{\Ahttps?://}
        tempdir = Dir.mktmpdir("maestrano-connector-rails-")
        at_exit { FileUtils.remove_entry(tempdir) }
        git :clone => "--quiet https://github.com/berardpi/maestrano-connector-rails/tree/include-frontend #{tempdir}"

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

gem 'rails', '4.2.4'
gem 'turbolinks'
gem 'jquery-rails'
gem 'puma'
gem 'figaro'
gem 'tzinfo-data', platforms: [:mingw, :mswin, :jruby]

gem 'maestrano-connector-rails'

gem 'sqlite3'

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

  run 'rails g connector:install'
  run 'bundle exec figaro install'
  run 'rake railties:install:migrations'
  run 'rake db:migrate'

  # Init repo and commit
  git :init
  git add: "."
  git commit: "-a -m 'Initial commit'"
end