module Maestrano::Connector::Rails
  class SynchronizationJob < ::ActiveJob::Base
    include Maestrano::Connector::Rails::Concerns::SynchronizationJob
  end
end
