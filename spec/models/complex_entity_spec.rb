require 'spec_helper'

describe Maestrano::Connector::Rails::ComplexEntity do

  #Connec specific methods
  describe 'connec specific methods' do
    describe 'connec_entities_names' do
      it { expect{ subject.connec_entities_names }.to raise_error('Not implemented') }
    end
    describe 'external_entities_names' do
      it { expect{ subject.external_entities_names }.to raise_error('Not implemented') }
    end
    describe 'connec_model_to_external_model!' do
      it { expect{ subject.connec_model_to_external_model!({}) }.to raise_error('Not implemented') }
    end
    describe 'external_model_to_connec_model!' do
      it { expect{ subject.external_model_to_connec_model!({}) }.to raise_error('Not implemented') }
    end
  end

  describe 'general methods' do
    subject { Maestrano::Connector::Rails::ComplexEntity.new }

    describe 'map_to_external_with_idmap' do
      let(:organization) { create(:organization) }
      let(:id) { '322j-bbfg4' }
      let(:entity) { {'id' => id, 'name' => 'John', 'updated_at' => 2.day.ago} }
      let(:mapped_entity) { {'first_name' => 'John'} }
      let(:connec_name) { 'connec_name' }
      let(:external_name) { 'external_name' }
      let(:sub_instance) { Maestrano::Connector::Rails::SubEntityBase.new }
      before {
        allow(sub_instance).to receive(:map_to).and_return(mapped_entity)
      }

      context 'when entity has no idmap' do
        it 'creates one' do
          expect{
            subject.map_to_external_with_idmap(entity, organization, connec_name, external_name, sub_instance)
            }.to change{ Maestrano::Connector::Rails::IdMap.count }.by(1)
        end
      end
      it 'returns the mapped entity with its idmap' do
        expect(subject.map_to_external_with_idmap(entity, organization, connec_name, external_name, sub_instance)).to eql({entity: mapped_entity, idmap: Maestrano::Connector::Rails::IdMap.last})
      end

      context 'when entity has an idmap without last_push_to_external' do
        let!(:idmap) { create(:idmap, organization: organization, connec_id: id, connec_entity: connec_name, last_push_to_external: nil, external_entity: external_name) }

        it 'returns the mapped entity with its idmap' do
          expect(subject.map_to_external_with_idmap(entity, organization, connec_name, external_name, sub_instance)).to eql({entity: mapped_entity, idmap: idmap})
        end
      end

      context 'when entity has an idmap with an older last_push_to_external' do
        let!(:idmap) { create(:idmap, organization: organization, connec_id: id, connec_entity: connec_name, last_push_to_external: 1.year.ago, external_entity: external_name) }

        it 'returns the mapped entity with its idmap' do
          expect(subject.map_to_external_with_idmap(entity, organization, connec_name, external_name, sub_instance)).to eql({entity: mapped_entity, idmap: idmap})
        end
      end

      context 'when entity has an idmap with a more recent last_push_to_external' do
        let!(:idmap) { create(:idmap, organization: organization, connec_id: id, connec_entity: connec_name, last_push_to_external: 1.second.ago, external_entity: external_name) }

        it 'discards the entity' do
          expect(subject.map_to_external_with_idmap(entity, organization, connec_name, external_name, sub_instance)).to be_nil
        end
      end
    end

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
        allow(subject).to receive(:connec_entities_names).and_return(%w(sc_e1 ScE2))
      }

      it 'calls get_connec_entities on each connec sub complex entities' do
        expect_any_instance_of(Entities::SubEntities::ScE1).to receive(:get_connec_entities).with(nil, nil, nil, {opts: true})
        expect_any_instance_of(Entities::SubEntities::ScE2).to receive(:get_connec_entities).with(nil, nil, nil, {opts: true})
        subject.get_connec_entities(nil, nil, nil, {opts: true})
      end

      let(:arr1) { [{'name' => 'Water'}, {'name' => 'Sugar'}] }
      let(:arr2) { [{'price' => 92}, {'price' => 300}] }
      it 'returns an hash of the connec_entities keyed by connec_entity_name' do
        allow_any_instance_of(Entities::SubEntities::ScE1).to receive(:get_connec_entities).and_return(arr1)
        allow_any_instance_of(Entities::SubEntities::ScE2).to receive(:get_connec_entities).and_return(arr2)
        expect(subject.get_connec_entities(nil, nil, nil, {opts: true})).to eql({'sc_e1' => arr1, 'ScE2' => arr2})
      end
    end

    describe 'get_external_entities' do
      before {
        allow(subject).to receive(:external_entities_names).and_return(%w(sc_e1 ScE2))
      }

      it 'calls get_external_entities on each connec sub complex entities' do
        expect_any_instance_of(Entities::SubEntities::ScE1).to receive(:get_external_entities).with(nil, nil, nil, {opts: true})
        expect_any_instance_of(Entities::SubEntities::ScE2).to receive(:get_external_entities).with(nil, nil, nil, {opts: true})
        subject.get_external_entities(nil, nil, nil, {opts: true})
      end

      let(:arr1) { [{'name' => 'Water'}, {'name' => 'Sugar'}] }
      let(:arr2) { [{'price' => 92}, {'price' => 300}] }
      it 'returns an hash of the external_entities keyed by external_entity_name' do
        allow_any_instance_of(Entities::SubEntities::ScE1).to receive(:get_external_entities).and_return(arr1)
        allow_any_instance_of(Entities::SubEntities::ScE2).to receive(:get_external_entities).and_return(arr2)
        expect(subject.get_external_entities(nil, nil, nil, {opts: true})).to eql({'sc_e1' => arr1, 'ScE2' => arr2})
      end
    end


    describe 'consolidate_and_map_data' do
      let(:opt) { {opt: true} }
      let(:organization) { create(:organization) }

      it 'calls external_model_to_connec_model!' do
        allow(subject).to receive(:connec_model_to_external_model!)
        expect(subject).to receive(:external_model_to_connec_model!).with({a: {}})
        subject.consolidate_and_map_data({}, {a: {}}, organization, opt)
      end

      it 'calls connec_model_to_external_model' do
        allow(subject).to receive(:external_model_to_connec_model!)
        expect(subject).to receive(:connec_model_to_external_model!).with({a: {}})
        subject.consolidate_and_map_data({a: {}}, {}, organization, opt)
      end

      describe 'connec_entities treatment' do
        #hash as it should be after connec_model_to_external_model!
        let(:connec_hash) {
          {
            'sc_e1' => {'ext1' => [{'name' => 'John'}, {'name' => 'Jane'}]},
            'ScE2' => {'ext1' => [{'name' => 'Robert'}], 'ext2' => [{'price' => 45}]}
          }
        }
        before{
          allow(subject).to receive(:external_model_to_connec_model!)
          allow(subject).to receive(:connec_model_to_external_model!)
        }

        it 'calls map_to_external_with_idmap on each entity' do
          expect(subject).to receive(:map_to_external_with_idmap).exactly(4).times
          subject.consolidate_and_map_data(connec_hash, {}, organization, opt)
        end
      end

      describe 'external_entities treatment' do
        #hash as it should be after external_model_to_connec_model!
        let(:id1) { '5678ttd3' }
        let(:id2) { '5678taa3' }
        let(:entity1) { {'id' => id1, 'name' => 'Robert'} }
        let(:entity2) { {'id' => id2, 'price' => 45} }
        let(:mapped_entity1) { {'first_name' => 'Robert'} }
        let(:mapped_entity2) { {'net_price' => 45} }
        let(:external_hash) {
          {
            'sc_e1' => {'connec1' => [entity1]},
            'ScE2' => {'connec1' => [entity1], 'connec2' => [entity2]}
          }
        }
        before{
          allow(subject).to receive(:external_model_to_connec_model!)
          allow(subject).to receive(:connec_model_to_external_model!)
          allow_any_instance_of(Entities::SubEntities::ScE1).to receive(:get_id_from_external_entity_hash).with(entity1).and_return(id1)
          allow_any_instance_of(Entities::SubEntities::ScE1).to receive(:get_last_update_date_from_external_entity_hash).and_return(1.minute.ago)
          allow_any_instance_of(Entities::SubEntities::ScE1).to receive(:map_to).with('connec1', entity1, organization).and_return(mapped_entity1)
          allow_any_instance_of(Entities::SubEntities::ScE2).to receive(:get_id_from_external_entity_hash).with(entity1).and_return(id1)
          allow_any_instance_of(Entities::SubEntities::ScE2).to receive(:get_id_from_external_entity_hash).with(entity2).and_return(id2)
          allow_any_instance_of(Entities::SubEntities::ScE2).to receive(:get_last_update_date_from_external_entity_hash).and_return(1.minute.ago)
          allow_any_instance_of(Entities::SubEntities::ScE2).to receive(:map_to).with('connec1', entity1, organization).and_return(mapped_entity1)
          allow_any_instance_of(Entities::SubEntities::ScE2).to receive(:map_to).with('connec2', entity2, organization).and_return(mapped_entity2)
        }

        context 'when entities have no idmaps' do
          it 'creates an idmap for each entity' do
            expect{
              subject.consolidate_and_map_data({}, external_hash, organization, opt)
            }.to change{ Maestrano::Connector::Rails::IdMap.count }.by(3)
          end

          it 'returns the entity with their new idmaps' do
            subject.consolidate_and_map_data({}, external_hash, organization, opt)
            expect(external_hash).to eql(            {
              'sc_e1' => {'connec1' => [{entity: mapped_entity1, idmap: Maestrano::Connector::Rails::IdMap.first}]},
              'ScE2' => {
                'connec1' => [{entity: mapped_entity1, idmap: Maestrano::Connector::Rails::IdMap.all[1]}],
                'connec2' => [{entity: mapped_entity2, idmap: Maestrano::Connector::Rails::IdMap.last}],
              }
            })
          end
        end

        context 'when entities have idmaps with more recent last_push_to_connec' do
          let!(:idmap1) { create(:idmap, organization: organization, external_id: id1, external_entity: 'sc_e1', connec_entity: 'connec1', last_push_to_connec: 1.second.ago) }
          let!(:idmap21) { create(:idmap, organization: organization, external_id: id1, external_entity: 'sce2', connec_entity: 'connec1', last_push_to_connec: 1.second.ago) }
          let!(:idmap22) { create(:idmap, organization: organization, external_id: id2, external_entity: 'sce2', connec_entity: 'connec2', last_push_to_connec: 1.second.ago) }

          it 'discards the entities' do
            subject.consolidate_and_map_data({}, external_hash, organization, opt)
            expect(external_hash).to eql(            {
              'sc_e1' => {'connec1' => []},
              'ScE2' => {
                'connec1' => [],
                'connec2' => [],
              }
            })
          end
        end

        context 'when entities have idmaps with older last_push_to_connec' do
          before{
            class Entities::SubEntities::Connec1 < Maestrano::Connector::Rails::SubEntityBase
            end
            class Entities::SubEntities::Connec2 < Maestrano::Connector::Rails::SubEntityBase
            end
            allow_any_instance_of(Entities::SubEntities::Connec1).to receive(:map_to).and_return({'name' => 'Jacob'})
          }
          let(:connec_id1) { '67ttf-5rr4d' }
          let!(:idmap1) { create(:idmap, organization: organization, external_id: id1, external_entity: 'sc_e1', connec_entity: 'connec1', last_push_to_connec: 1.year.ago, connec_id: connec_id1) }
          let!(:idmap21) { create(:idmap, organization: organization, external_id: id1, external_entity: 'sce2', connec_entity: 'connec1', last_push_to_connec: 1.year.ago) }
          let!(:idmap22) { create(:idmap, organization: organization, external_id: id2, external_entity: 'sce2', connec_entity: 'connec2', last_push_to_connec: 1.year.ago) }
          let(:connec_hash) { {'connec1' => {'sc_e1' => [{'id' => connec_id1, 'first_name' => 'Jacob', 'updated_at' => 1.hour.ago}]}, 'connec2' => {'sc_e1' => [], 'ScE2' => []}} }

          context 'without conflict' do
            it 'returns the entity with their idmaps' do
              subject.consolidate_and_map_data(connec_hash, external_hash, organization, opt)
              expect(external_hash).to eql({
                'sc_e1' => {'connec1' => [{entity: mapped_entity1, idmap: idmap1}]},
                'ScE2' => {
                  'connec1' => [{entity: mapped_entity1, idmap: idmap21}],
                  'connec2' => [{entity: mapped_entity2, idmap: idmap22}],
                }
              })
            end
          end

          context 'with conflict' do
            context 'with option connec_preemption' do
              context 'set to true' do
                let(:opt) { {connec_preemption: true} }

                it 'keeps the connec entities' do
                  subject.consolidate_and_map_data(connec_hash, external_hash, organization, opt)
                  expect(connec_hash).to eq({'connec1' => {'sc_e1' => [{entity: {'name' => 'Jacob'}, idmap: idmap1}]}, 'connec2' => {'sc_e1' => [], 'ScE2' => []}})
                  expect(external_hash).to eql({
                    'sc_e1' => {'connec1' => []},
                    'ScE2' => {
                      'connec1' => [{entity: mapped_entity1, idmap: idmap21}],
                      'connec2' => [{entity: mapped_entity2, idmap: idmap22}],
                    }
                  })
                end
              end
              context 'set to false' do
                let(:opt) { {connec_preemption: false} }

                it 'keeps the external entities' do
                  subject.consolidate_and_map_data(connec_hash, external_hash, organization, opt)
                  expect(connec_hash).to eq({'connec1' => {'sc_e1' => []}, 'connec2' => {'sc_e1' => [], 'ScE2' => []}})
                  expect(external_hash).to eql({
                    'sc_e1' => {'connec1' => [{entity: mapped_entity1, idmap: idmap1}]},
                    'ScE2' => {
                      'connec1' => [{entity: mapped_entity1, idmap: idmap21}],
                      'connec2' => [{entity: mapped_entity2, idmap: idmap22}],
                    }
                  })
                end
              end
            end

            context 'without option' do
              context 'with a more recently updated external entity' do
                it 'keeps the external entity' do
                  subject.consolidate_and_map_data(connec_hash, external_hash, organization, opt)
                  expect(connec_hash).to eq({'connec1' => {'sc_e1' => []}, 'connec2' => {'sc_e1' => [], 'ScE2' => []}})
                  expect(external_hash).to eql({
                    'sc_e1' => {'connec1' => [{entity: mapped_entity1, idmap: idmap1}]},
                    'ScE2' => {
                      'connec1' => [{entity: mapped_entity1, idmap: idmap21}],
                      'connec2' => [{entity: mapped_entity2, idmap: idmap22}],
                    }
                  })
                end
              end

              context 'with a more recently updated connec entity' do
                let(:connec_hash) { {'connec1' => {'sc_e1' => [{'id' => connec_id1, 'first_name' => 'Jacob', 'updated_at' => 1.second.ago}]}, 'connec2' => {'sc_e1' => [], 'ScE2' => []}} }

                it 'keeps the connec entities' do
                  subject.consolidate_and_map_data(connec_hash, external_hash, organization, opt)
                  expect(connec_hash).to eq({'connec1' => {'sc_e1' => [{entity: {'name' => 'Jacob'}, idmap: idmap1}]}, 'connec2' => {'sc_e1' => [], 'ScE2' => []}})
                  expect(external_hash).to eql({
                    'sc_e1' => {'connec1' => []},
                    'ScE2' => {
                      'connec1' => [{entity: mapped_entity1, idmap: idmap21}],
                      'connec2' => [{entity: mapped_entity2, idmap: idmap22}],
                    }
                  })
                end
              end
            end
          end
        end
      end
    end

    describe 'push_entities_to_connec' do
      let(:mapped_entity_with_idmap) { {entity: {}, idmap: nil} }
      let(:external_hash) {
        {
          'sc_e1' => {'connec1' => [mapped_entity_with_idmap]},
          'ScE2' => {'connec1' => [mapped_entity_with_idmap, mapped_entity_with_idmap], 'connec2' => [mapped_entity_with_idmap]}
        }
      }

      it 'calls push_entities_to_connec on each sub complex entity' do
        expect_any_instance_of(Entities::SubEntities::ScE1).to receive(:push_entities_to_connec_to).once.with(nil, [mapped_entity_with_idmap], 'connec1', nil)
        expect_any_instance_of(Entities::SubEntities::ScE2).to receive(:push_entities_to_connec_to).twice
        subject.push_entities_to_connec(nil, external_hash, nil)
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
        expect_any_instance_of(Entities::SubEntities::ScE1).to receive(:push_entities_to_external_to).once.with(nil, [mapped_entity_with_idmap], 'ext1', nil)
        expect_any_instance_of(Entities::SubEntities::ScE2).to receive(:push_entities_to_external_to).twice
        subject.push_entities_to_external(nil, connec_hash, nil)
      end
    end
  end
end