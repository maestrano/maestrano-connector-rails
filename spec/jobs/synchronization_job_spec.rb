require 'spec_helper'

describe Maestrano::Connector::Rails::SynchronizationJob do
  let(:organization) { create(:organization) }
  subject { Maestrano::Connector::Rails::SynchronizationJob.perform_now(organization, {}) }

  describe 'perform' do
    context 'with sync_enabled set to false' do
      it 'does not creates a syncrhonization' do
        expect{ subject }.to change{ Maestrano::Connector::Rails::Synchronization.count }.by(0)
      end

      it 'does not calls sync entity' do
        expect_any_instance_of(Maestrano::Connector::Rails::SynchronizationJob).to_not receive(:sync_entity)
        subject
      end
    end

    context 'with sync_enabled set to true' do
      before {organization.update(sync_enabled: true)}

      it 'creates a synchronization' do
        expect{ subject }.to change{ Maestrano::Connector::Rails::Synchronization.count }.by(1)
      end

      it 'calls sync entity on all the organization synchronized entities set to true' do
        organization.synchronized_entities[organization.synchronized_entities.keys.first] = false
        expect_any_instance_of(Maestrano::Connector::Rails::SynchronizationJob).to receive(:sync_entity).exactly(organization.synchronized_entities.count - 1).times

        subject
      end

      context 'with options' do
        context 'with only_entities' do
          subject { Maestrano::Connector::Rails::SynchronizationJob.perform_now(organization, {only_entities: %w(people price)}) }

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
        expect_any_instance_of(Entities::Person).to receive(:get_external_entities)
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
        expect_any_instance_of(Entities::SomeStuff).to receive(:get_external_entities)
        expect_any_instance_of(Entities::SomeStuff).to receive(:consolidate_and_map_data).and_return({})
        expect_any_instance_of(Entities::SomeStuff).to receive(:push_entities_to_external)
        expect_any_instance_of(Entities::SomeStuff).to receive(:push_entities_to_connec)
        expect_any_instance_of(Entities::SomeStuff).to receive(:after_sync)
        subject.sync_entity('some stuff', organization, nil, nil, nil, {})
      end
    end
  end
end