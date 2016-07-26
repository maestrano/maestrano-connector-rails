require 'spec_helper'

describe Maestrano::Connector::Rails::ComplexEntity do

  describe 'class methods' do
    subject { Maestrano::Connector::Rails::ComplexEntity }
    
      describe 'connec_entities_names' do
        it { expect{ subject.connec_entities_names }.to raise_error('Not implemented') }
      end
      describe 'external_entities_names' do
        it { expect{ subject.external_entities_names }.to raise_error('Not implemented') }
      end

      describe 'count_entities' do
        it 'returns the biggest array size' do
          entities = {
            'people' => [*1..27],
            'organizations' => [*1..39],
            'items' => []
          }
          expect(subject.count_entities(entities)).to eql(39)
        end
      end
  end

  describe 'instance methods' do
    let!(:organization) { create(:organization, uid: 'cld-123') }
    let!(:connec_client) { Maestrano::Connec::Client[organization.tenant].new(organization.uid) }
    let!(:external_client) { Object.new }
    let(:opts) { {} }
    subject { Maestrano::Connector::Rails::ComplexEntity.new(organization, connec_client, external_client, opts) }

    #Complex specific methods
    describe 'complex specific methods' do
      describe 'connec_model_to_external_model' do
        it { expect{ subject.connec_model_to_external_model({}) }.to raise_error('Not implemented') }
      end
      describe 'external_model_to_connec_model' do
        it { expect{ subject.external_model_to_connec_model({}) }.to raise_error('Not implemented') }
      end
    end

    describe 'filter_connec_entities' do
      it { expect(subject.filter_connec_entities({'lead' => [{a: 2}]})).to eql({'lead' => [{a: 2}]}) }
    end

    describe 'methods with sub complex entities' do
      before {
        module Entities::SubEntities
        end
        class Entities::SubEntities::ScE1 < Maestrano::Connector::Rails::SubEntityBase
        end
        class Entities::SubEntities::ScE2 < Maestrano::Connector::Rails::SubEntityBase
        end
      }

      describe 'get_connec_entities' do
        before {
          allow(subject.class).to receive(:connec_entities_names).and_return(%w(sc_e1 ScE2))
        }

        it 'calls get_connec_entities on each connec sub complex entities' do
          expect_any_instance_of(Entities::SubEntities::ScE1).to receive(:get_connec_entities).with(nil)
          expect_any_instance_of(Entities::SubEntities::ScE2).to receive(:get_connec_entities).with(nil)
          subject.get_connec_entities(nil)
        end

        let(:arr1) { [{'name' => 'Water'}, {'name' => 'Sugar'}] }
        let(:arr2) { [{'price' => 92}, {'price' => 300}] }
        it 'returns an hash of the connec_entities keyed by connec_entity_name' do
          allow_any_instance_of(Entities::SubEntities::ScE1).to receive(:get_connec_entities).and_return(arr1)
          allow_any_instance_of(Entities::SubEntities::ScE2).to receive(:get_connec_entities).and_return(arr2)
          expect(subject.get_connec_entities(nil)).to eql({'sc_e1' => arr1, 'ScE2' => arr2})
        end
      end

      describe 'get_external_entities' do
        before {
          allow(subject.class).to receive(:external_entities_names).and_return(%w(sc_e1 ScE2))
        }

        it 'calls get_external_entities on each connec sub complex entities' do
          expect_any_instance_of(Entities::SubEntities::ScE1).to receive(:get_external_entities_wrapper).with(nil)
          expect_any_instance_of(Entities::SubEntities::ScE2).to receive(:get_external_entities_wrapper).with(nil)
          subject.get_external_entities_wrapper(nil)
        end

        let(:arr1) { [{'name' => 'Water'}, {'name' => 'Sugar'}] }
        let(:arr2) { [{'price' => 92}, {'price' => 300}] }
        it 'returns an hash of the external_entities keyed by external_entity_name' do
          allow_any_instance_of(Entities::SubEntities::ScE1).to receive(:get_external_entities_wrapper).and_return(arr1)
          allow_any_instance_of(Entities::SubEntities::ScE2).to receive(:get_external_entities_wrapper).and_return(arr2)
          expect(subject.get_external_entities_wrapper(nil)).to eql({'sc_e1' => arr1, 'ScE2' => arr2})
        end
      end


      describe 'consolidate and map methods' do
        let(:human_name) { 'Jabba' }
        let(:mapped_entity) { {mapped: 'entity'} }
        let(:date) { 2.hour.ago }

        describe 'consolidate_and_map_data' do
            before{
              allow(subject).to receive(:external_model_to_connec_model).and_return({})
              allow(subject).to receive(:connec_model_to_external_model).and_return({})
            }

          it 'calls external_model_to_connec_model' do
            expect(subject).to receive(:external_model_to_connec_model).with({a: {}}).and_return({})
            subject.consolidate_and_map_data({}, {a: {}})
          end

          it 'calls connec_model_to_external_model' do
            expect(subject).to receive(:connec_model_to_external_model).with({a: {}}).and_return({})
            subject.consolidate_and_map_data({a: {}}, {})
          end

          it 'calls the consolidation on both connec and external and returns an hash with the results' do
            expect(subject).to receive(:consolidate_and_map_connec_entities).with({}, {}).and_return({connec_result: 1})
            expect(subject).to receive(:consolidate_and_map_external_entities).with({}).and_return({ext_result: 1})
            expect(subject.consolidate_and_map_data({}, {})).to eql({connec_entities: {connec_result: 1}, external_entities: {ext_result: 1}})
          end
        end

        describe 'consolidate_and_map_external_entities' do
          let(:entity) { {'id' => id, 'name' => 'Jane'} }
          let(:id) { 'id' }
          let(:external_name) { 'sc_e1' }
          let(:connec_name) { 'connec1' }
          let(:modeled_external_entities) { {external_name => {connec_name => [entity]}} }
          before {
            allow(Entities::SubEntities::ScE1).to receive(:external?).and_return(true)
            allow(Entities::SubEntities::ScE1).to receive(:entity_name).and_return(external_name)
            allow(Entities::SubEntities::ScE1).to receive(:id_from_external_entity_hash).and_return(id)
            allow(Entities::SubEntities::ScE1).to receive(:object_name_from_external_entity_hash).and_return(human_name)
            allow(Entities::SubEntities::ScE1).to receive(:last_update_date_from_external_entity_hash).and_return(date)
            allow_any_instance_of(Entities::SubEntities::ScE1).to receive(:map_to).and_return(mapped_entity)
          }

          context 'when idmap exists' do
            let!(:idmap) { create(:idmap, organization: organization, connec_entity: connec_name.downcase, external_entity: external_name.downcase, external_id: id) }

            it 'does not create one' do
              expect{
                subject.consolidate_and_map_external_entities(modeled_external_entities)
              }.to_not change{ Maestrano::Connector::Rails::IdMap.count }
            end

            it 'returns the mapped entity with the idmap' do
              expect(subject.consolidate_and_map_external_entities(modeled_external_entities)).to eql({external_name => {connec_name => [{entity: mapped_entity, idmap: idmap}]}})
            end

            context 'when to_connec is false' do
              before { idmap.update(to_connec: false) }

              it 'discards the entity' do
                expect(subject.consolidate_and_map_external_entities(modeled_external_entities)).to eql({external_name => {connec_name => []}})
              end
            end

            context 'when entity is inactive' do
              before {
                allow(Entities::SubEntities::ScE1).to receive(:inactive_from_external_entity_hash?).and_return(true)
              }

              it 'discards the entity' do
                expect(subject.consolidate_and_map_external_entities(modeled_external_entities)).to eql({external_name => {connec_name => []}})
              end

              it 'updates the idmaps' do
                subject.consolidate_and_map_external_entities(modeled_external_entities)
                expect(idmap.reload.external_inactive).to be true
              end
            end

            context 'when last_push_to_connec is recent' do
              before { idmap.update(last_push_to_connec: 2.second.ago) }

              it 'discards the entity' do
                expect(subject.consolidate_and_map_external_entities(modeled_external_entities)).to eql({external_name => {connec_name => []}})
              end
            end

          end
        end

        describe 'consolidate_and_map_connec_entities' do
          let(:id) { 'external-unfolded-id' }
          let(:connec_id) { 'connec-id' }
          let(:entity) { {'id' => id, 'name' => 'John', 'updated_at' => date} }
          let(:modeled_connec_entities) { {connec_name => {external_name => [entity]}} }
          let(:modeled_external_entities) { {} }
          let(:connec_name) { 'sc_e1' }
          let(:external_name) { 'ext1' }
          let(:id_refs_only_connec_entity) { {a: 1} }
          before{
            allow(Entities::SubEntities::ScE1).to receive(:external?).and_return(false)
            allow(Entities::SubEntities::ScE1).to receive(:entity_name).and_return(connec_name)
            allow_any_instance_of(Entities::SubEntities::ScE1).to receive(:map_to).with(external_name, entity).and_return(mapped_entity)
            allow(Entities::SubEntities::ScE1).to receive(:object_name_from_connec_entity_hash).and_return(human_name)
            allow(Maestrano::Connector::Rails::ConnecHelper).to receive(:unfold_references).and_return({entity: entity, connec_id: connec_id, id_refs_only_connec_entity: id_refs_only_connec_entity})
          }

          context 'when idmaps do not exist' do
            it 'creates the idmaps with a name and returns the mapped entities with their idmaps' do
              expect{
                expect(subject.consolidate_and_map_connec_entities(modeled_connec_entities, {})).to eql({connec_name => {external_name => [{entity: {mapped: 'entity'}, idmap: Maestrano::Connector::Rails::IdMap.first, id_refs_only_connec_entity: id_refs_only_connec_entity}]}})
              }.to change{ Maestrano::Connector::Rails::IdMap.count }.by(1)
              expect(Maestrano::Connector::Rails::IdMap.last.name).to eql(human_name)
            end
          end

          context 'when idmap exists' do
            let!(:idmap1) { create(:idmap, organization: organization, connec_entity: connec_name.downcase, external_entity: external_name.downcase, external_id: id, connec_id: connec_id) }

            it 'does not create an idmap' do
              expect{
                subject.consolidate_and_map_connec_entities(modeled_connec_entities, {})
              }.to_not change{ Maestrano::Connector::Rails::IdMap.count }
            end

            it 'returns the entity with its idmap' do
              expect(subject.consolidate_and_map_connec_entities(modeled_connec_entities, {})).to eql({connec_name => {external_name => [{entity: {mapped: 'entity'}, idmap: idmap1, id_refs_only_connec_entity: id_refs_only_connec_entity}]}})
            end

            context 'when external inactive' do
              before { idmap1.update(external_inactive: true) }
              it 'discards the entity' do
                expect(subject.consolidate_and_map_connec_entities(modeled_connec_entities, {})).to eql({connec_name => {external_name => []}})
              end
            end

            context 'when to external flag is false' do
              before { idmap1.update(to_external: false) }
              it 'discards the entity' do
                expect(subject.consolidate_and_map_connec_entities(modeled_connec_entities, {})).to eql({connec_name => {external_name => []}})
              end
            end

            context 'when last_push_to_external is recent' do
              before { idmap1.update(last_push_to_external: 2.second.ago) }
              it 'discards the entity' do
                expect(subject.consolidate_and_map_connec_entities(modeled_connec_entities, {})).to eql({connec_name => {external_name => []}})
              end
            end

            context 'when conflict' do
              let(:external_entity_1) { {'id' => id} }
              let(:modeled_external_entities) { {external_name => {connec_name => [external_entity_1]}} }
              before {
                allow(Entities::SubEntities::ScE1).to receive(:id_from_external_entity_hash).and_return(id)
              }

              context 'with opts' do
                context 'with connec preemption false' do
                  it 'discards the entity and keep the external one' do
                    subject.instance_variable_set(:@opts, {connec_preemption: false})
                    expect(subject.consolidate_and_map_connec_entities(modeled_connec_entities, modeled_external_entities)).to eql({connec_name => {external_name => []}})
                    expect(modeled_external_entities[external_name][connec_name]).to_not be_empty
                  end
                end

                context 'with connec preemption true' do
                  it 'keeps the entity and discards the external one' do
                    subject.instance_variable_set(:@opts, {connec_preemption: true})
                    expect(subject.consolidate_and_map_connec_entities(modeled_connec_entities, modeled_external_entities)).to eql({connec_name => {external_name => [{entity: {mapped: 'entity'}, idmap: Maestrano::Connector::Rails::IdMap.first, id_refs_only_connec_entity: id_refs_only_connec_entity}]}})
                    expect(modeled_external_entities[external_name][connec_name]).to be_empty
                  end
                end
              end

              context 'without opts' do
                before {
                  allow(Entities::SubEntities::ScE1).to receive(:last_update_date_from_external_entity_hash).and_return(external_date)
                }

                context 'with connec one more recent' do
                  let(:external_date) { 1.year.ago } 
                  let(:date) { 1.day.ago } 

                  it 'keeps the entity and discards the external one' do
                    expect(subject.consolidate_and_map_connec_entities(modeled_connec_entities, modeled_external_entities)).to eql({connec_name => {external_name => [{entity: {mapped: 'entity'}, idmap: Maestrano::Connector::Rails::IdMap.first, id_refs_only_connec_entity: id_refs_only_connec_entity}]}})
                    expect(modeled_external_entities[external_name][connec_name]).to be_empty
                  end
                end

                context 'with external one more recent' do
                  let(:external_date) { 1.month.ago } 
                  let(:date) { 1.year.ago } 

                  it 'discards the entity and keep the external one' do
                    expect(subject.consolidate_and_map_connec_entities(modeled_connec_entities, modeled_external_entities)).to eql({connec_name => {external_name => []}})
                    expect(modeled_external_entities[external_name][connec_name]).to_not be_empty
                  end
                end
              end
            end
          end
        end
      end


      describe 'push_entities_to_connec' do
        let(:idmap) { nil }
        let(:mapped_entity_with_idmap) { {entity: {}, idmap: idmap} }
        let(:external_hash) {
          {
            'sc_e1' => {'Connec1' => [mapped_entity_with_idmap]},
            'ScE2' => {'Connec1' => [mapped_entity_with_idmap, mapped_entity_with_idmap], 'connec2' => [mapped_entity_with_idmap]}
          }
        }

        it 'calls push_entities_to_connec on each sub complex entity' do
          expect_any_instance_of(Entities::SubEntities::ScE1).to receive(:push_entities_to_connec_to).once.with([mapped_entity_with_idmap], 'Connec1')
          expect_any_instance_of(Entities::SubEntities::ScE2).to receive(:push_entities_to_connec_to).twice
          subject.push_entities_to_connec(external_hash)
        end

        describe 'full call' do
          let(:idmap) { create(:idmap, organization: organization) }
          before {
            [Entities::SubEntities::ScE1, Entities::SubEntities::ScE2].each do |klass|
              allow(klass).to receive(:external?).and_return(true)
              allow(klass).to receive(:entity_name).and_return('n')
            end
            allow(connec_client).to receive(:batch).and_return(ActionDispatch::Response.new(200, {}, {results: [{status: 200, body: {connec1s: {id: [{provider: 'connec', id: 'connec-id'}]}}}]}.to_json, {}), ActionDispatch::Response.new(200, {}, {results: [{status: 200, body: {connec1s: {id: [{provider: 'connec', id: 'connec-id'}]}}}]}.to_json, {}), ActionDispatch::Response.new(200, {}, {results: [{status: 200, body: {connec2s: {id: [{provider: 'connec', id: 'connec-id'}]}}}]}.to_json, {}))
          }
          it 'is successful' do
            subject.push_entities_to_connec(external_hash)
            idmap.reload
            expect(idmap.message).to be nil
          end
        end
      end

      describe 'push_entities_to_external' do
        let(:mapped_entity_with_idmap) { {entity: {}, idmap: nil} }
        let(:connec_hash) {
          {
            'sc_e1' => {'ext1' => [mapped_entity_with_idmap]},
            'ScE2' => {'ext1' => [mapped_entity_with_idmap, mapped_entity_with_idmap], 'ext2' => [mapped_entity_with_idmap]}
          }
        }

        it 'calls push_entities_to_connec on each sub complex entity' do
          expect_any_instance_of(Entities::SubEntities::ScE1).to receive(:push_entities_to_external_to).once.with([mapped_entity_with_idmap], 'ext1')
          expect_any_instance_of(Entities::SubEntities::ScE2).to receive(:push_entities_to_external_to).twice
          subject.push_entities_to_external(connec_hash)
        end
      end
    end
  end
end