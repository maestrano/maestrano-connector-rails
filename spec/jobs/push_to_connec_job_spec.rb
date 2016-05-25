require 'spec_helper'

describe Maestrano::Connector::Rails::PushToConnecJob do
  let(:organization) { create(:organization) }
  let(:entity_name1) { 'entity1' }
  let(:entity_name2) { 'entity2' }
  before {
    class Entities::Entity1 < Maestrano::Connector::Rails::Entity
    end
    allow_any_instance_of(Entities::Entity1).to receive(:push_entities_to_connec)
    allow(Entities::Entity1).to receive(:external_entity_name).and_return('ext_entity1')
    class Entities::Entity2 < Maestrano::Connector::Rails::ComplexEntity
    end
    allow_any_instance_of(Entities::Entity2).to receive(:consolidate_and_map_data).and_return({})
    allow_any_instance_of(Entities::Entity2).to receive(:push_entities_to_connec)
    allow(Entities::Entity2).to receive(:connec_entities_names).and_return(['Connec name'])
    allow(Entities::Entity2).to receive(:external_entities_names).and_return(%w(Subs ll))
    module Entities::SubEntities end;
    class Entities::SubEntities::Sub < Maestrano::Connector::Rails::SubEntityBase
    end
    allow(Maestrano::Connector::Rails::Entity).to receive(:entities_list).and_return([entity_name1, entity_name2])
    allow(Maestrano::Connector::Rails::Entity).to receive(:id_from_external_entity_hash).and_return('11')
  }
  let(:entity11) { {first_name: 'John'} }
  let(:entity12) { {first_name: 'Jane'} }
  let(:entity21) { {job: 'Pizza guy'} }
  let(:hash) { {'ext_entity1' => [entity11, entity12], 'Subs' => [entity21]} }
  subject { Maestrano::Connector::Rails::PushToConnecJob.perform_now(organization, hash) }

  describe 'with organization sync enabled set to false' do
    before { organization.update(sync_enabled: false, oauth_uid: 'lala') }

    it 'does nothing' do
      expect(Maestrano::Connec::Client).to_not receive(:new)
      subject
    end
  end

  describe 'with no oauth uid' do
    before { organization.update(sync_enabled: true, oauth_uid: nil) }

    it 'does nothing' do
      expect(Maestrano::Connec::Client).to_not receive(:new)
      subject
    end
  end

  describe 'with sync enabled and an oauth uid' do
    before { organization.update(sync_enabled: true, oauth_uid: 'lala') }

    describe 'with a non existing entity' do
      let(:hash) { {'lala' => []} }

      it 'logs a warning' do
        expect(Rails.logger).to receive(:warn)
        subject
      end
    end

    describe 'with entities in synchronized entities' do

      describe 'complex entity' do
        before { organization.update(synchronized_entities: {:"#{entity_name1}" => false, :"#{entity_name2}" => true})}

        it 'calls consolidate and map data on the complex entity with the right arguments' do
          expect_any_instance_of(Entities::Entity2).to receive(:consolidate_and_map_data).with({"Connec name" => []}, {"Subs"=>[entity21], "ll"=>[]})
          expect_any_instance_of(Entities::Entity2).to receive(:push_entities_to_connec)
          subject
        end

        it 'does not calls methods on the non complex entity' do
          expect_any_instance_of(Entities::Entity1).to_not receive(:consolidate_and_map_data)
          subject
        end

        it 'calls before and after sync' do
          expect_any_instance_of(Entities::Entity2).to receive(:before_sync)
          expect_any_instance_of(Entities::Entity2).to receive(:after_sync)
          subject
        end
      end

      describe 'non complex entity' do
        before { organization.update(synchronized_entities: {:"#{entity_name1}" => true, :"#{entity_name2}" => false})}

        it 'calls consolidate_and_map_data on the non complex entity with the right arguments' do
          expect_any_instance_of(Entities::Entity1).to receive(:consolidate_and_map_data).with([], [entity11, entity12]).and_return({})
          expect_any_instance_of(Entities::Entity1).to receive(:push_entities_to_connec)
          subject
        end

        it 'does not calls methods on the complex entity' do
          allow_any_instance_of(Entities::Entity1).to receive(:consolidate_and_map_data).and_return({})
          expect_any_instance_of(Entities::Entity2).to_not receive(:consolidate_and_map_data)
          subject
        end

        it 'calls before and after sync' do
          allow_any_instance_of(Entities::Entity1).to receive(:consolidate_and_map_data).and_return({})
          expect_any_instance_of(Entities::Entity1).to receive(:before_sync)
          expect_any_instance_of(Entities::Entity1).to receive(:after_sync)
          subject
        end
      end
    end
  end
end