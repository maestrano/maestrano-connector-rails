require 'spec_helper'
require 'sidekiq/testing'

describe Maestrano::Connector::Rails::PushToConnecWorker do
  describe 'class method' do
    let(:organization) { create(:organization) }
    subject { Maestrano::Connector::Rails::PushToConnecWorker }

    Sidekiq::Testing.fake!
    it 'perform_async add a new job' do
      expect {
        subject.perform_async(1, 2, 3)
      }.to change(subject.jobs, :size).by(1)
    end

    describe 'unique_args' do
      it do
        entities_hash = {entity_2: [{'id': 'id2'}, {'id': 'id1'}], entity_1: [{'id': 'id4'}, {'id': nil}, {'id': 'id3'}, {'id': 'id3'}]}
        expect(subject.unique_args([organization, entities_hash])).to eq([organization.id, [:entity_1, :entity_2]])
      end
    end
  end


end

