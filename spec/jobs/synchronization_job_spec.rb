require 'spec_helper'

describe Maestrano::Connector::Rails::SynchronizationJob do
  let(:organization) { create(:organization) }
  let(:opts) { {} }
  subject { Maestrano::Connector::Rails::SynchronizationJob.perform_now(organization.id, opts) }

  def does_not_perform
    expect_any_instance_of(Maestrano::Connector::Rails::SynchronizationJob).to_not receive(:sync_entity)
    expect{ subject }.to change{ Maestrano::Connector::Rails::Synchronization.count }.by(0)
  end

  def performs
    expect{ subject }.to change{ Maestrano::Connector::Rails::Synchronization.count }.by(1)
  end

  describe 'perform' do
    context 'with sync_enabled set to false' do
      it { does_not_perform }
    end

    context 'with sync_enabled set to true' do
      before { organization.update(sync_enabled: true)}

      context 'with a sync still running for less than 30 minutes' do
        let!(:running_sync) { create(:synchronization, organization: organization, status: 'RUNNING', created_at: 29.minutes.ago) }
        it { does_not_perform }
      end

      context 'with a sync still running for more than 30 minutes' do
        let!(:running_sync) { create(:synchronization, organization: organization, status: 'RUNNING', created_at: 31.minutes.ago) }
        it { performs }
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
            it { performs }
          end
        end

        context 'three last sync failed and last sync more than 24 hours ago' do
          before {
            3.times do
              organization.synchronizations.create(status: 'ERROR', created_at: 2.day.ago, updated_at: 2.day.ago)
            end
          }
          it { performs }
        end

        context 'three sync failed but last sync is successfull' do
          before {
            3.times do
              organization.synchronizations.create(status: 'ERROR', created_at: 2.hour.ago)
            end
            organization.synchronizations.create(status: 'SUCCESS', created_at: 1.hour.ago)
          }
          it { performs }
        end
      end


      context 'first sync' do
        it 'does two half syncs' do
          expect_any_instance_of(Maestrano::Connector::Rails::SynchronizationJob).to receive(:first_sync_entity).exactly(2 * organization.synchronized_entities.count).times
          subject
        end
      end

      context 'subsequent sync' do
        let!(:old_sync) { create(:synchronization, partial: false, status: 'SUCCESS', organization: organization) }

        it { performs }

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

        context 'with sync_from' do
          let(:opts) { { sync_from: sync_from } }
          let(:sync_from) { Time.new(2002, 10, 31, 2, 2, 2, "+02:00") }

          it { performs }

          it 'passes the correct sync_from dates' do
            organization.synchronized_entities.each do |entity, _|
              expect_any_instance_of(Maestrano::Connector::Rails::SynchronizationJob).to receive(:sync_entity)
                .with(entity.to_s, organization, anything, anything, sync_from, anything)
            end

            subject
          end
        end
      end
    end
  end

  describe 'other methods' do
    subject { Maestrano::Connector::Rails::SynchronizationJob.new }

    describe 'sync_entity' do

      context 'non complex entity' do
        before {
          class Entities::Person < Maestrano::Connector::Rails::Entity
          end
        }

        it 'calls the seven methods' do
          expect_any_instance_of(Entities::Person).to receive(:before_sync)
          expect_any_instance_of(Entities::Person).to receive(:get_connec_entities).and_return([])
          expect_any_instance_of(Entities::Person).to receive(:get_external_entities_wrapper).and_return([])
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
          expect_any_instance_of(Entities::SomeStuff).to receive(:get_connec_entities).and_return({})
          expect_any_instance_of(Entities::SomeStuff).to receive(:get_external_entities_wrapper).and_return({})
          expect_any_instance_of(Entities::SomeStuff).to receive(:consolidate_and_map_data).and_return({})
          expect_any_instance_of(Entities::SomeStuff).to receive(:push_entities_to_external)
          expect_any_instance_of(Entities::SomeStuff).to receive(:push_entities_to_connec)
          expect_any_instance_of(Entities::SomeStuff).to receive(:after_sync)
          subject.sync_entity('some stuff', organization, nil, nil, nil, {})
        end
      end
    end

    describe 'first_sync_entity' do
      let(:batch_limit) { 50 }

      context 'non complex entity' do
        let(:external_entities1) { [] }
        let(:external_entities2) { [] }
        let(:connec_entities1) { [] }
        let(:connec_entities2) { [] }
        before {
          class Entities::Person < Maestrano::Connector::Rails::Entity
          end
          allow_any_instance_of(Entities::Person).to receive(:get_connec_entities).and_return(connec_entities1, connec_entities2)
          allow_any_instance_of(Entities::Person).to receive(:get_external_entities_wrapper).and_return(external_entities1, external_entities2)
          allow_any_instance_of(Entities::Person).to receive(:consolidate_and_map_data).and_return({})
          allow_any_instance_of(Entities::Person).to receive(:push_entities_to_external)
          allow_any_instance_of(Entities::Person).to receive(:push_entities_to_connec)
        }

        context 'with pagination' do
          context 'with more than 50 entities' do
            let(:external_entities1) { [*1..50] }
            let(:external_entities2) { [*51..60] }

            it 'calls perform_sync several time' do
              expect_any_instance_of(Entities::Person).to receive(:opts_merge!).twice
              expect(subject).to receive(:perform_sync).twice.and_call_original

              subject.first_sync_entity('person', organization, nil, nil, nil, {}, true)
            end
          end

          context 'with less than 50 entities' do
            let(:external_entities1) { [*1..40] }

            it 'calls perform_sync once' do
              expect_any_instance_of(Entities::Person).to receive(:opts_merge!).once.with({__skip: 0})
              expect(subject).to receive(:perform_sync).once.and_call_original

              subject.first_sync_entity('person', organization, nil, nil, nil, {}, true)
            end
          end
        end

        context 'without pagination' do
          context 'when more than 50 entities' do
            let(:external_entities1) { [*1..60] }

            it 'calls perform_sync once' do
              expect_any_instance_of(Entities::Person).to receive(:opts_merge!).once.with({__skip: 0})
              expect(subject).to receive(:perform_sync).once.and_call_original

              subject.first_sync_entity('person', organization, nil, nil, nil, {}, true)
            end
          end

          context 'when exactly 50 entities' do
            let(:external_entities1) { [*1..50] }
            let(:external_entities1) { [*1..50] }

            it 'calls perform_sync twice but no infinite loop' do
              expect_any_instance_of(Entities::Person).to receive(:opts_merge!).twice
              expect(subject).to receive(:perform_sync).twice.and_call_original

              subject.first_sync_entity('person', organization, nil, nil, nil, {}, true)
            end
          end
        end
      end
    end
  end
end
