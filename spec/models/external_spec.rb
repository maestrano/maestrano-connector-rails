require 'spec_helper'

describe Maestrano::Connector::Rails::External do
  subject { Maestrano::Connector::Rails::External }

  describe 'external_name' do
    it { expect(subject.external_name).to eql('Dummy app') }
  end

  describe 'get_client' do
    let(:organization) { create(:organization) }

    it { expect(subject.get_client(organization)).to eql(nil) }
  end

  describe 'entities_list' do
    it { expect(subject.entities_list).to eql(%w(entity1 entity2))}
  end
end