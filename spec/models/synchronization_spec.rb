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
    describe 'success?' do
      it { expect(Maestrano::Connector::Rails::Synchronization.new(status: 'SUCCESS').success?).to be(true) }
      it { expect(Maestrano::Connector::Rails::Synchronization.new(status: 'ERROR').success?).to be(false) }
    end

    describe 'error?' do
      it { expect(Maestrano::Connector::Rails::Synchronization.new(status: 'ERROR').error?).to be(true) }
      it { expect(Maestrano::Connector::Rails::Synchronization.new(status: 'RUNNING').error?).to be(false) }
    end

    describe 'running?' do
      it { expect(Maestrano::Connector::Rails::Synchronization.new(status: 'RUNNING').running?).to be(true) }
      it { expect(Maestrano::Connector::Rails::Synchronization.new(status: 'ERROR').running?).to be(false) }
    end

    describe 'mark_as_success' do
      let(:sync) { create(:synchronization, status: 'RUNNING') }

      it 'set the synchronization status to success' do
        sync.mark_as_success
        sync.reload
        expect(sync.status).to eql('SUCCESS')
      end
    end

    describe 'mark_as_error' do
      let(:sync) { create(:synchronization, status: 'RUNNING') }

      it 'set the synchronization status to error with the message' do
        sync.mark_as_error('msg')
        sync.reload
        expect(sync.status).to eql('ERROR')
        expect(sync.message).to eql('msg')
      end
    end

    describe 'mark_as_partial' do
      let(:sync) { create(:synchronization, partial: false) }

      it 'set the synchronization status to error with the message' do
        sync.mark_as_partial
        sync.reload
        expect(sync.partial).to be(true)
      end
    end

    describe 'clean_synchronizations on creation' do
      let!(:organization) { create(:organization) }

      context 'when less than 100 syncs' do
        before {
          2.times do
            create(:synchronization, organization: organization)
          end
        }

        it 'does nothing' do
          expect{ organization.synchronizations.create(status: 'RUNNING') }.to change{ organization.synchronizations.count }.by(1)
        end
      end

      context 'when more than 100 syncs' do
        before {
          100.times do
            create(:synchronization, organization: organization)
          end
        }

        it 'destroy the right syncs' do
          sync = organization.synchronizations.create(status: 'RUNNING')
          expect(Maestrano::Connector::Rails::Synchronization.count).to eql(100)
          expect(Maestrano::Connector::Rails::Synchronization.all.map(&:id)).to eql([*2..101])
        end

      end
    end
  end
end