source 'http://rubygems.org'

gemspec

# Add dependencies to develop your gem here.
group :development do
  gem 'activerecord-jdbcsqlite3-adapter', platforms: :jruby
  gem 'sqlite3', platforms: :ruby
end

group :test do
  gem 'jsonapi-resources'
  gem 'jsonapi-resources-matchers', require: false
  gem 'pundit'
  gem 'pundit-matchers'
  gem 'pundit-resources'
end
