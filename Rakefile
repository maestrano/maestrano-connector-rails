# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts 'Run `bundle install` to install missing gems'
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://guides.rubygems.org/specification-reference/ for more options
  gem.name = 'maestrano-connector-rails'
  gem.homepage = 'http://github.com/maestrano/maestrano-connector-rails'
  gem.license = 'MIT'
  gem.summary = 'Rails framework to build connector with Maestrano'
  gem.description = 'Maestrano is the next generation marketplace for SME applications. See https://maestrano.com for details.'
  gem.email = 'developers@maestrano.com'
  gem.authors = ['Maestrano', 'Pierre Berard', 'Marco Bagnasco']
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

# Rubocop
require 'rubocop/rake_task'
RuboCop::RakeTask.new

APP_RAKEFILE = File.expand_path('../spec/dummy/Rakefile', __FILE__)
load 'rails/tasks/engine.rake'

require 'rspec/core'
require 'rspec/core/rake_task'

desc 'Run all specs in spec directory (excluding plugin specs)'
RSpec::Core::RakeTask.new(spec: 'app:db:test:prepare')

task default: [:spec, :rubocop]
