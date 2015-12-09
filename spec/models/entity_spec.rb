require 'spec_helper'

describe Maestrano::Connector::Rails::Entity do

  describe 'class methods' do
    subject { Maestrano::Connector::Rails::Entity }

    describe 'entities_list' do
      it { expect(subject.entities_list).to eql(%w(entity1 entity2))}
    end
  end

  describe 'instance methods' do
    subject { Maestrano::Connector::Rails::Entity.new }

    describe 'Mapper methods' do
      before(:each) {
        class AMapper
          extend HashMapper
          def self.set_organization(organization_id)
          end
        end
        allow_any_instance_of(Maestrano::Connector::Rails::Entity).to receive(:mapper_class).and_return(AMapper)
      }

      # Mapper methods
      describe 'set_mapper_organization' do
        it 'calls the mapper set organization with the id' do
          expect(AMapper).to receive(:set_organization).with(12)
          subject.set_mapper_organization(12)
        end
      end

      describe 'unset_mapper_organization' do
        it 'calls the mapper set organization with nil' do
          expect(AMapper).to receive(:set_organization).with(nil)
          subject.unset_mapper_organization
        end
      end

      describe 'map_to_external' do
        it 'calls the setter normalize' do
          expect(AMapper).to receive(:normalize).with({})
          subject.map_to_external({})
        end
      end

      describe 'map_to_connec' do
        it 'calls the setter denormalize' do
          expect(AMapper).to receive(:denormalize).with({})
          subject.map_to_connec({})
        end
      end
    end


    # Connec! methods
    describe 'connec_methods' do
      let(:organization) { create(:organization) }
      let(:client) { Maestrano::Connec::Client.new(organization.uid) }
      let(:connec_name) { 'person' }
      let(:sync) { create(:synchronization) }
      before {
        allow_any_instance_of(Maestrano::Connector::Rails::Entity).to receive(:connec_entity_name).and_return(connec_name)
      }

      describe 'get_connec_entities' do
        describe 'with response' do
          before {
            allow(client).to receive(:get).and_return(ActionDispatch::Response.new(200, {}, {people: []}.to_json, {}))
          }

          context 'when opts[:full_sync] is true' do
            it 'performs a full get' do
              expect(client).to receive(:get).with("/#{connec_name.downcase.pluralize}")
              subject.get_connec_entities(client, nil, {full_sync: true})
            end
          end

          context 'when there is no last sync' do
            it 'performs a full get' do
              expect(client).to receive(:get).with("/#{connec_name.downcase.pluralize}")
              subject.get_connec_entities(client, nil)
            end
          end

          context 'when there is a last sync' do
            it 'performs a time limited get' do
              uri_param = URI.encode("$filter=updated_at gt '#{sync.updated_at.iso8601}'")
              expect(client).to receive(:get).with("/#{connec_name.downcase.pluralize}?#{uri_param}")
              subject.get_connec_entities(client, sync)
            end
          end
        end
        #TODO: pagination, errors
      end

      describe 'push_entities_to_connec' do
        #TODO
      end

      describe 'push_entities_to_connec_to' do
        #TODO
      end

      describe 'create_entity_to_connec' do
        #TODO
      end

      describe 'update_entity_to_connec' do
        #TODO
      end

      describe 'map_to_external_with_idmap' do
        #TODO
      end
    end


    # External methods
    describe 'external methods' do
      let(:connec_name) { 'connec_name' }
      let(:external_name) { 'external_name' }
      let(:idmap1) { create(:idmap) }
      let(:idmap2) { create(:idmap, external_id: nil, external_entity: nil, last_push_to_external: nil) }
      let(:entity1) { {name: 'John'} }
      let(:entity2) { {name: 'Jane'} }
      let(:entity_with_idmap1) { {entity: entity1, idmap: idmap1} }
      let(:entity_with_idmap2) { {entity: entity2, idmap: idmap2} }
      let(:entities_with_idmaps) { [entity_with_idmap1, entity_with_idmap2] }

      describe 'get_external_entities' do
        it { expect{ subject.get_external_entities(nil, nil, nil) }.to raise_error }
      end

      describe 'push_entities_to_external' do
        it 'calls push_entities_to_external_to' do
          allow_any_instance_of(Maestrano::Connector::Rails::Entity).to receive(:external_entity_name).and_return(external_name)
          expect(subject).to receive(:push_entities_to_external_to).with(nil, entities_with_idmaps, external_name)
          subject.push_entities_to_external(nil, entities_with_idmaps)
        end
      end

      describe 'push_entities_to_external_to' do
        it 'calls push_entity_to_external for each entity' do
          allow_any_instance_of(Maestrano::Connector::Rails::Entity).to receive(:connec_entity_name).and_return(connec_name)
          expect(subject).to receive(:push_entity_to_external).twice
          subject.push_entities_to_external_to(nil, entities_with_idmaps, external_name)
        end
      end

      describe 'push_entity_to_external' do
        context 'when the entity idmap has an external id' do
          it 'calls update_entity_to_external' do
            expect(subject).to receive(:update_entity_to_external).with(nil, entity1, idmap1.external_id, external_name)
            subject.push_entity_to_external(nil, entity_with_idmap1, external_name)
          end

          it 'updates the idmap last push to external' do
            allow_any_instance_of(Maestrano::Connector::Rails::Entity).to receive(:update_entity_to_external)
            time_before = idmap1.last_push_to_external
            subject.push_entity_to_external(nil, entity_with_idmap1, external_name)
            idmap1.reload
            expect(idmap1.last_push_to_external).to_not eql(time_before)
          end
        end

        context 'when the entity idmap does not have an external id' do
          it 'calls create_entity_to_external' do
            expect(subject).to receive(:create_entity_to_external).with(nil, entity2, external_name)
            subject.push_entity_to_external(nil, entity_with_idmap2, external_name)
          end

          it 'updates the idmap external id, entity and last push' do
            allow_any_instance_of(Maestrano::Connector::Rails::Entity).to receive(:create_entity_to_external).and_return('999111')
            subject.push_entity_to_external(nil, entity_with_idmap2, external_name)
            idmap2.reload
            expect(idmap2.external_id).to eql('999111')
            expect(idmap2.external_entity).to eql(external_name)
            expect(idmap2.last_push_to_external).to_not be_nil
          end
        end
      end

      describe 'create_entity_to_external' do
        it { expect{ subject.create_entity_to_external(nil, nil, nil) }.to raise_error }
      end

      describe 'update_entity_to_external' do
        it { expect{ subject.update_entity_to_external(nil, nil, nil, nil) }.to raise_error }
      end

      describe 'get_id_from_external_entity_hash' do
        it { expect{ subject.get_id_from_external_entity_hash(nil) }.to raise_error }
      end

      describe 'get_last_update_date_from_external_entity_hash' do
        it { expect{ subject.get_last_update_date_from_external_entity_hash(nil) }.to raise_error }
      end
    end


    # General methods
    describe 'consolidate_and_map_data' do
      #TODO
    end


    # Entity specific methods
    describe 'connec_entity_name' do
      it { expect{ subject.connec_entity_name }.to raise_error }
    end

    describe 'external_entity_name' do
      it { expect{ subject.external_entity_name }.to raise_error }
    end

    describe 'mapper_class' do
      it { expect{ subject.mapper_class }.to raise_error }
    end
  end

end