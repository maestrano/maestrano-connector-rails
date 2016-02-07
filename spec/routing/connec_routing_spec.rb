require "spec_helper"

describe Maestrano::ConnecController, type: :controller do
  routes { Maestrano::Connector::Rails::Engine.routes }

  describe "routing" do

    it "routes to #notifications" do
      expect(:post => '/maestrano/connec/notifications/default').to route_to("maestrano/connec#notifications", tenant: 'default')
    end
  end
end
