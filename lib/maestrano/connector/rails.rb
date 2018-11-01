require 'maestrano-rails'
require 'retriable'

require 'haml-rails'
require 'bootstrap-sass'
require 'autoprefixer-rails'

require 'hash_mapper'

require 'config'
require 'figaro'

require 'attr_encrypted'

require 'sidekiq'
require 'sidekiq-cron'
require 'sidekiq-unique-jobs'
require 'slim'

module Maestrano
  module Connector
    module Rails
      class Engine < ::Rails::Engine
        # isolate_namespace Maestrano::Connector::Rails
      end
    end
  end
end
