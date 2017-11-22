# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Maestrano::Api::SynchronizationsController, type: :controller do
  include JsonApiController
  routes { Maestrano::Connector::Rails::Engine.routes }

  it_behaves_like 'an app IDM endpoint'
end
