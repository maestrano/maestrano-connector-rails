# frozen_string_literal: true

module Maestrano
  class SynchronizationsController < Maestrano::Rails::WebHookController
    include Maestrano::Concerns::SynchronizationsController
  end
end
