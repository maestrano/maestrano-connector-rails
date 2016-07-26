require 'spec_helper'

describe Maestrano::Connector::Rails::External do
  subject { Maestrano::Connector::Rails::External }

  before {
    allow(Maestrano::Connector::Rails::External).to receive(:external_name).and_call_original
    allow(Maestrano::Connector::Rails::External).to receive(:get_client).and_call_original
    allow(Maestrano::Connector::Rails::External).to receive(:entities_list).and_call_original
  }

  describe 'external_name' do
    it { expect{ subject.external_name }.to raise_error(RuntimeError) }
  end

  describe 'get_client' do
    it { expect{ subject.get_client(nil) }.to raise_error(RuntimeError) }
  end

  describe 'entities_list' do
    it { expect{ subject.entities_list }.to raise_error(RuntimeError) }
  end

  describe 'create_account_link' do
    it { expect{ subject.create_account_link }.to raise_error(RuntimeError) }
  end
end