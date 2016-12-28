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
      expect(JSON.parse(response.body)).to eql('framework_version'=>'1.2', 'ci_branch' => nil, 'ci_commit' => nil, 'env' => 'test', 'ruby_version' => RUBY_VERSION, 'ruby_engine' => RUBY_ENGINE)
    end
  end
end
