require 'spec_helper'

describe VersionController, type: :controller do
  routes { Maestrano::Connector::Rails::Engine.routes }

  describe 'index' do
    subject { get :index, format: :json }
    before {
      allow(Gem).to receive(:loaded_specs).and_return({'maestrano-connector-rails' => Gem::Specification.new('maestrano-connector-rails', '1.2')})
    }

    it 'returns a version hash' do
      subject
      expect(JSON.parse(response.body)).to eql({"framework_version"=>"1.2", "env" => "test"})
    end
  end
end
