# frozen_string_literal: true

$:.push File.expand_path("../lib", __FILE__)
require 'maestrano/connector/rails/version'

Gem::Specification.new do |s|
  s.name         = "maestrano-connector-rails"
  s.version      = Maestrano::Connector::Rails::VERSION.dup
  s.authors      = ["Maestrano"]
  s.email        = "developers@maestrano.com"
  s.summary      = "Rails framework to build connector with Maestrano"
  s.description  = "Maestrano is the next generation marketplace for SME applications. See https://sme.maestrano.com for details."
  s.homepage     = "https://github.com/maestrano/maestrano-connector-rails"
  s.license      = "MIT"

  s.required_ruby_version = '>= 2.3.0'
  s.files        = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(spec|template)/})
  end
  s.require_paths = ["lib"]

  s.extra_rdoc_files = [
    "LICENSE",
    "README.md"
  ]

  s.add_runtime_dependency('rails', '~> 4.2.9')
  s.add_runtime_dependency('maestrano-rails', '~> 1.0.4')
  s.add_runtime_dependency('attr_encrypted', '~> 1.4.0')
  s.add_runtime_dependency('autoprefixer-rails')
  s.add_runtime_dependency('bootstrap-sass')
  s.add_runtime_dependency('config')
  s.add_runtime_dependency('figaro')
  s.add_runtime_dependency('jquery-rails', '>= 4.0.4')
  s.add_runtime_dependency('jsonapi-resources')
  s.add_runtime_dependency('haml-rails')
  s.add_runtime_dependency('hash_mapper', '>= 0.2.2')
  s.add_runtime_dependency('pundit')
  s.add_runtime_dependency('pundit-resources')
  s.add_runtime_dependency('retriable', '~> 3.1.2')
  s.add_runtime_dependency('sidekiq', '~> 4.2.9')
  s.add_runtime_dependency('sidekiq-cron')
  s.add_runtime_dependency('sidekiq-unique-jobs')
  s.add_runtime_dependency('slim')

  s.add_development_dependency('bundler')
  s.add_development_dependency('factory_girl_rails')
  s.add_development_dependency('github_changelog_generator')
  s.add_development_dependency('rdoc')
  s.add_development_dependency('rspec-rails')
  s.add_development_dependency('rubocop', '~> 0.52')
  s.add_development_dependency('shoulda')
  s.add_development_dependency('shoulda-matchers', '~> 3.1')
  s.add_development_dependency('simplecov', '>= 0')
  s.add_development_dependency('timecop')
  s.add_development_dependency('webmock')
end
