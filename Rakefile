# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://guides.rubygems.org/specification-reference/ for more options
  gem.name = "maestrano-connector-rails"
  gem.homepage = "http://github.com/maestrano/maestrano-connector-rails"
  gem.license = "MIT"
  gem.summary = "Rails framework to build connector with Maestrano"
  gem.description = "Maestrano is the next generation marketplace for SME applications. See https://maestrano.com for details."
  gem.email = "pierre.berard@maestrano.com"
  gem.authors = ["Pierre Berard"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

APP_RAKEFILE = File.expand_path("../spec/dummy/Rakefile", __FILE__)
load 'rails/tasks/engine.rake'

require 'rspec/core'
require 'rspec/core/rake_task'

desc "Run all specs in spec directory (excluding plugin specs)"
RSpec::Core::RakeTask.new(:spec => 'app:db:test:prepare')

task :default => :spec

# require 'rake/testtask'
# Rake::TestTask.new(:test) do |test|
#   test.libs << 'lib' << 'test'
#   test.pattern = 'test/**/test_*.rb'
#   test.verbose = true
# end

# desc "Code coverage detail"
# task :simplecov do
#   ENV['COVERAGE'] = "true"
#   Rake::Task['test'].execute
# end

# task :default => :test

# require 'rdoc/task'
# Rake::RDocTask.new do |rdoc|
#   version = File.exist?('VERSION') ? File.read('VERSION') : ""

#   rdoc.rdoc_dir = 'rdoc'
#   rdoc.title = "maestrano-connector-rails #{version}"
#   rdoc.rdoc_files.include('README*')
#   rdoc.rdoc_files.include('lib/**/*.rb')
# end
