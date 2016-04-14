require 'spec_helper'

describe Maestrano::Connector::Rails::Synchronization do

  # Attributes
  it { should validate_presence_of(:status) }

  # Indexes
  it { should have_db_index(:organization_id) }

  #Associations
  it { should belong_to(:organization) }

  describe 'class methods' do
    subject { Maestrano::Connector::Rails::Synchronization }

    describe 'create_running' do
      let(:organization) { create(:organization) }

      it 'creates an organization' do
        expect{ subject.create_running(organization) }.to change{ Maestrano::Connector::Rails::Synchronization.count }.by(1)
      end

      it { expect(subject.create_running(organization).status).to eql('RUNNING') }
    end
  end

  describe 'instance methods' do
    describe 'is_success?' do
      it { expect(Maestrano::Connector::Rails::Synchronization.new(status: 'SUCCESS').is_success?).to be(true) }
      it { expect(Maestrano::Connector::Rails::Synchronization.new(status: 'ERROR').is_success?).to be(false) }
    end

    describe 'is_error?' do
      it { expect(Maestrano::Connector::Rails::Synchronization.new(status: 'ERROR').is_error?).to be(true) }
      it { expect(Maestrano::Connector::Rails::Synchronization.new(status: 'RUNNING').is_error?).to be(false) }
    end

    describe 'is_running?' do
      it { expect(Maestrano::Connector::Rails::Synchronization.new(status: 'RUNNING').is_running?).to be(true) }
      it { expect(Maestrano::Connector::Rails::Synchronization.new(status: 'ERROR').is_running?).to be(false) }
    end

    describe 'set_success' do
      let(:sync) { create(:synchronization, status: 'RUNNING') }

      it 'set the synchronization status to success' do
        sync.set_success
        sync.reload
        expect(sync.status).to eql('SUCCESS')
      end
    end

    describe 'set_error' do
      let(:sync) { create(:synchronization, status: 'RUNNING') }

      it 'set the synchronization status to error with the message' do
        sync.set_error('msg')
        sync.reload
        expect(sync.status).to eql('ERROR')
        expect(sync.message).to eql('msg')
      end
    end

    describe 'set_partial' do
      let(:sync) { create(:synchronization, partial: false) }

      it 'set the synchronization status to error with the message' do
        sync.set_partial
        sync.reload
        expect(sync.partial).to be(true)
      end
    end

    describe 'clean_synchronizations' do
      let!(:organization) { create(:organization) }
      let!(:sync) { create(:synchronization, organization: organization) }
      let!(:sync2) { create(:synchronization, organization: organization) }

      context 'when less than 100 syncs' do
        it 'does nothing' do
          expect{ sync.clean_synchronizations }.to_not change{ organization.synchronizations.count }
        end
      end

      context 'when more than 100 syncs' do
        before {
          allow_any_instance_of(ActiveRecord::Associations::CollectionProxy).to receive(:count).and_return(102)
        }

        it 'destroy the idmaps' do
          expect{ sync.clean_synchronizations }.to change{ Maestrano::Connector::Rails::Synchronization.count }.by(-2)
        end
      end
    end
  end
end