require 'spec_helper'

describe Maestrano::Connector::Rails::SynchronizationJob do
  let(:organization) { create(:organization) }
  let(:opts) { {} }
  subject { Maestrano::Connector::Rails::SynchronizationJob.perform_now(organization, opts) }

  def does_not_perform
    expect_any_instance_of(Maestrano::Connector::Rails::SynchronizationJob).to_not receive(:sync_entity)
    expect{ subject }.to change{ Maestrano::Connector::Rails::Synchronization.count }.by(0)
  end

  def performes
    expect{ subject }.to change{ Maestrano::Connector::Rails::Synchronization.count }.by(1)
  end

  describe 'perform' do
    context 'with sync_enabled set to false' do
      it { does_not_perform }
    end

    context 'with sync_enabled set to true' do
      before {organization.update(sync_enabled: true)}

      context 'with a sync still running for less than 30 minutes' do
        let!(:running_sync) { create(:synchronization, organization: organization, status: 'RUNNING', created_at: 29.minutes.ago) }
        it { does_not_perform }
      end

      context 'with a sync still running for more than 30 minutes' do
        let!(:running_sync) { create(:synchronization, organization: organization, status: 'RUNNING', created_at: 31.minutes.ago) }
        it { performes }
      end

      describe 'recovery mode' do
        context 'three last sync failed and last sync less than 24 hours ago' do
          before {
            3.times do
              organization.synchronizations.create(status: 'ERROR', created_at: 2.hour.ago)
            end
          }
          it { does_not_perform }

          context 'synchronization is forced' do
            let(:opts) { {forced: true} }
            it { performes }
          end
        end

        context 'three last sync failed and last sync more than 24 hours ago' do
          before {
            3.times do
              organization.synchronizations.create(status: 'ERROR', created_at: 2.day.ago, updated_at: 2.day.ago)
            end
          }
          it { performes }
        end

        context 'three sync failed but last sync is successfull' do
          before {
            3.times do
              organization.synchronizations.create(status: 'ERROR', created_at: 2.hour.ago)
            end
            organization.synchronizations.create(status: 'SUCCESS', created_at: 1.hour.ago)
          }
          it { performes }
        end
      end

      it { performes }

      context 'first sync' do
        it 'does two half syncs' do
          expect_any_instance_of(Maestrano::Connector::Rails::SynchronizationJob).to receive(:sync_entity).exactly(2 * organization.synchronized_entities.count).times
          subject
        end
      end

      context 'subsequent sync' do
        let!(:old_sync) { create(:synchronization, partial: false, status: 'SUCCESS', organization: organization) }

        it 'calls sync entity on all the organization synchronized entities set to true' do
          organization.synchronized_entities[organization.synchronized_entities.keys.first] = false
          expect_any_instance_of(Maestrano::Connector::Rails::SynchronizationJob).to receive(:sync_entity).exactly(organization.synchronized_entities.count - 1).times

          subject
        end

        context 'with options' do
          context 'with only_entities' do
            let(:opts) { {only_entities: %w(people price)} }

            it 'calls sync entity on the specified entities' do
              expect_any_instance_of(Maestrano::Connector::Rails::SynchronizationJob).to receive(:sync_entity).twice

              subject
            end

            it 'set the current syncrhonization as partial' do
              subject
              expect(Maestrano::Connector::Rails::Synchronization.last.partial).to be(true)
            end
          end
        end
      end

    end
  end

  describe 'sync_entity' do
    subject { Maestrano::Connector::Rails::SynchronizationJob.new }

    context 'non complex entity' do
      before {
        class Entities::Person < Maestrano::Connector::Rails::Entity
        end
      }

      it 'calls the seven methods' do
        expect_any_instance_of(Entities::Person).to receive(:before_sync)
        expect_any_instance_of(Entities::Person).to receive(:get_connec_entities)
        expect_any_instance_of(Entities::Person).to receive(:get_external_entities_wrapper)
        expect_any_instance_of(Entities::Person).to receive(:consolidate_and_map_data).and_return({})
        expect_any_instance_of(Entities::Person).to receive(:push_entities_to_external)
        expect_any_instance_of(Entities::Person).to receive(:push_entities_to_connec)
        expect_any_instance_of(Entities::Person).to receive(:after_sync)
        subject.sync_entity('person', organization, nil, nil, nil, {})
      end
    end

    context 'complex entity' do
      before {
        class Entities::SomeStuff < Maestrano::Connector::Rails::ComplexEntity
        end
      }

      it 'calls the seven methods' do
        expect_any_instance_of(Entities::SomeStuff).to receive(:before_sync)
        expect_any_instance_of(Entities::SomeStuff).to receive(:get_connec_entities)
        expect_any_instance_of(Entities::SomeStuff).to receive(:get_external_entities_wrapper)
        expect_any_instance_of(Entities::SomeStuff).to receive(:consolidate_and_map_data).and_return({})
        expect_any_instance_of(Entities::SomeStuff).to receive(:push_entities_to_external)
        expect_any_instance_of(Entities::SomeStuff).to receive(:push_entities_to_connec)
        expect_any_instance_of(Entities::SomeStuff).to receive(:after_sync)
        subject.sync_entity('some stuff', organization, nil, nil, nil, {})
      end
    end
  end
end