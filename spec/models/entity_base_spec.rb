require 'spec_helper'

describe Maestrano::Connector::Rails::EntityBase do
  describe 'instance methods' do
    let!(:organization) { create(:organization, uid: 'cld-123') }
    let!(:connec_client) { Maestrano::Connec::Client[organization.tenant].new(organization.uid) }
    let!(:external_client) { Object.new }
    let(:opts) { {} }
    subject { Maestrano::Connector::Rails::EntityBase.new(organization, connec_client, external_client, opts) }

    describe 'opts_merge!' do
      let(:opts) { {a: 1, opts: 2} }

      it 'merges options with the instance variable' do
        subject.opts_merge!(opts: 3, test: 'test')
        expect(subject.instance_variable_get(:@opts)).to eql(a: 1, opts: 3, test: 'test')
      end
    end
  end
end