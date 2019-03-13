# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

# Add dependencies to develop your gem here.
group :development do
  gem 'activerecord-jdbcsqlite3-adapter', platforms: :jruby
  gem 'sqlite3', '~> 1.3.13', platforms: :ruby
end

group :test do
  gem 'jsonapi-resources'
  gem 'jsonapi-resources-matchers', require: false
  gem 'pundit'
  gem 'pundit-matchers'
  gem 'pundit-resources'
end
