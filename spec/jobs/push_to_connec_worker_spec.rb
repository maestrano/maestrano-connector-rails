require 'spec_helper'
require 'sidekiq/testing'

describe Maestrano::Connector::Rails::PushToConnecWorker do
  describe 'class methods' do
    let(:organization) { create(:organization) }
    subject { Maestrano::Connector::Rails::PushToConnecWorker }

    Sidekiq::Testing.fake!
    it 'perform_async add a new job' do
      expect_any_instance_of(Maestrano::Connector::Rails::PushToConnecJob).to receive(:perform)
      expect {
        subject.perform_async(organization.id, {}, 3)
      }.to change(subject.jobs, :size).by(1)

      expect {
        subject.drain
      }.to change(subject.jobs, :size).by(-1)
    end

    it 'raise an error if the organization can t be found' do
      subject.perform_async(-1, {}, 3)
      expect {
        subject.drain
      }.to raise_error(ActiveRecord::RecordNotFound)
    end


    describe 'unique_args' do
      it do
        entities_hash = {entity_2: [{'id': 'id2'}, {'id': 'id1'}], entity_1: [{'id': 'id4'}, {'id': nil}, {'id': 'id3'}, {'id': 'id3'}]}
        expect(subject.unique_args([organization.id, entities_hash])).to eq([organization.id, [:entity_1, :entity_2]])
      end
    end
  end
end

