require 'spec_helper'

describe Maestrano::Connector::Rails::Entity do

  describe 'class methods' do
    subject { Maestrano::Connector::Rails::Entity }

    describe 'entities_list' do
      it { expect(subject.entities_list).to eql(%w(entity1 entity2))}
    end

    # IdMap methods
    describe 'idmaps mehtods' do
      before {
        allow(subject).to receive(:connec_entity_name).and_return('Ab')
        allow(subject).to receive(:external_entity_name).and_return('Ab')
      }
      let(:n_hash) { {connec_entity: 'ab', external_entity: 'ab'} }

      it { expect(subject.names_hash).to eql(n_hash) }
      it {
        expect(Maestrano::Connector::Rails::IdMap).to receive(:find_or_create_by).with(n_hash.merge(id: 'lala'))
        subject.find_or_create_idmap({id: 'lala'})
      }
      it {
        expect(Maestrano::Connector::Rails::IdMap).to receive(:find_by).with(n_hash.merge(id: 'lala'))
        subject.find_idmap({id: 'lala'})
      }
      describe 'creates' do
        let(:organization) { create(:organization) }
        let(:connec_entity) { {'id' => 'lala'} }
        before {
          allow(subject).to receive(:object_name_from_external_entity_hash).and_return('name_e')
          allow(subject).to receive(:object_name_from_connec_entity_hash).and_return('name_c')
          allow(subject).to receive(:id_from_external_entity_hash).and_return('id')
        }

        it {
          expect(Maestrano::Connector::Rails::IdMap).to receive(:create).with(n_hash.merge(connec_id: 'lala', name: 'name_c', organization_id: organization.id))
          subject.create_idmap_from_connec_entity(connec_entity, organization)
        }
        it {
          expect(Maestrano::Connector::Rails::IdMap).to receive(:create).with(n_hash.merge(external_id: 'id', name: 'name_e', organization_id: organization.id))
          subject.create_idmap_from_external_entity({}, organization)
        }
      end
    end

    describe 'normalized_connec_entity_name' do
      before {
        allow(subject).to receive(:connec_entity_name).and_return(connec_name)
      }
      context 'for a singleton resource' do
        before {
          allow(subject).to receive(:singleton?).and_return(true)
        }

        context 'for a simple name' do
          let(:connec_name) { 'Person' }
          it { expect(subject.normalized_connec_entity_name).to eql('person') }
        end

        context 'for a complex name' do
          let(:connec_name) { 'Credit Note' }
          it { expect(subject.normalized_connec_entity_name).to eql('credit_note') }
        end
      end

      context 'for a non singleton resource' do
        before {
          allow(subject).to receive(:singleton?).and_return(false)
        }

        context 'for a simple name' do
          let(:connec_name) { 'Person' }
          it { expect(subject.normalized_connec_entity_name).to eql('people') }
        end

        context 'for a complex name' do
          let(:connec_name) { 'Credit Note' }
          it { expect(subject.normalized_connec_entity_name).to eql('credit_notes') }
        end
      end
    end

    describe 'id_from_external_entity_hash' do
      it { expect{ subject.id_from_external_entity_hash(nil) }.to raise_error('Not implemented') }
    end

    describe 'last_update_date_from_external_entity_hash' do
      it { expect{ subject.last_update_date_from_external_entity_hash(nil) }.to raise_error('Not implemented') }
    end

    # Entity specific methods
    describe 'singleton?' do
      it 'is false by default' do
        expect(subject.singleton?).to be false
      end
    end

    describe 'connec_entity_name' do
      it { expect{ subject.connec_entity_name }.to raise_error('Not implemented') }
    end

    describe 'external_entity_name' do
      it { expect{ subject.external_entity_name }.to raise_error('Not implemented') }
    end

    describe 'mapper_class' do
      it { expect{ subject.mapper_class }.to raise_error('Not implemented') }
    end

    describe 'object_name_from_connec_entity_hash' do
      it { expect{ subject.object_name_from_connec_entity_hash({}) }.to raise_error('Not implemented') }
    end

    describe 'object_name_from_external_entity_hash' do
      it { expect{ subject.object_name_from_external_entity_hash({}) }.to raise_error('Not implemented') }
    end
  end

  describe 'instance methods' do
    subject { Maestrano::Connector::Rails::Entity.new }

    describe 'Mapper methods' do
      before(:each) {
        class AMapper
          extend HashMapper
        end
        allow(subject.class).to receive(:mapper_class).and_return(AMapper)
      }

      describe 'map_to_external' do
        it 'calls the mapper normalize' do
          expect(AMapper).to receive(:normalize).with({}).and_return({})
          subject.map_to_external({}, nil)
        end

        context 'with references' do
          let!(:organization) { create(:organization) }
          let!(:idmap) { create(:idmap, organization: organization) }
          before {
            clazz = Maestrano::Connector::Rails::Entity
            allow(clazz).to receive(:find_idmap).and_return(idmap)
            allow(clazz).to receive(:references).and_return([{reference_class: clazz, connec_field: 'organization_id', external_field: 'contact_id'}])
          }

          it 'returns the mapped entity with its references' do
            expect(subject.map_to_external({'organization_id' => 'abcd'}, organization)).to eql({contact_id: idmap.external_id})
          end
        end
      end

      describe 'map_to_connec' do
        it 'calls the mapper denormalize' do
          expect(AMapper).to receive(:denormalize).with({}).and_return({})
          subject.map_to_connec({}, nil)
        end

        context 'with references' do
          let!(:organization) { create(:organization) }
          let!(:idmap) { create(:idmap, organization: organization) }
          before {
            clazz = Maestrano::Connector::Rails::Entity
            allow(clazz).to receive(:find_idmap).and_return(idmap)
            allow(clazz).to receive(:references).and_return([{reference_class: clazz, connec_field: 'organization_id', external_field: 'contact_id'}])
          }

          it 'returns the mapped entity with its references' do
            expect(subject.map_to_connec({'contact_id' => 'abcd'}, organization)).to eql({organization_id: idmap.connec_id})
          end
        end
      end
    end

    # Connec! methods
    describe 'connec_methods' do
      let(:organization) { create(:organization) }
      let(:client) { Maestrano::Connec::Client.new(organization.uid) }
      let(:connec_name) { 'Person' }
      let(:external_name) { 'external_name' }
      let(:sync) { create(:synchronization) }
      before {
        allow(subject.class).to receive(:connec_entity_name).and_return(connec_name)
        allow(subject.class).to receive(:external_entity_name).and_return(external_name)
      }

      describe 'get_connec_entities' do
        describe 'when write only' do
          before {
            allow(subject.class).to receive(:can_read_connec?).and_return(false)
            allow(client).to receive(:get).and_return(ActionDispatch::Response.new(200, {}, {people: [{first_name: 'Lea'}]}.to_json, {}))
          }

          it { expect(subject.get_connec_entities(client, nil, organization)).to eql([]) }
        end

        describe 'with response' do
          context 'for a singleton resource' do
            before {
              allow(client).to receive(:get).and_return(ActionDispatch::Response.new(200, {}, {person: []}.to_json, {}))
              allow(subject.class).to receive(:singleton?).and_return(true)
            }

            it 'calls get with a singularize url' do
              expect(client).to receive(:get).with("/#{connec_name.downcase}")
              subject.get_connec_entities(client, nil, organization)
            end
          end

          context 'for a non singleton resource' do
            before {
              allow(client).to receive(:get).and_return(ActionDispatch::Response.new(200, {}, {people: []}.to_json, {}))
            }

            context 'when opts[:full_sync] is true' do
              it 'performs a full get' do
                expect(client).to receive(:get).with("/#{connec_name.downcase.pluralize}")
                subject.get_connec_entities(client, nil, organization, {full_sync: true})
              end
            end

            context 'when there is no last sync' do
              it 'performs a full get' do
                expect(client).to receive(:get).with("/#{connec_name.downcase.pluralize}")
                subject.get_connec_entities(client, nil, organization)
              end
            end

            context 'when there is a last sync' do
              it 'performs a time limited get' do
                uri_param = URI.encode("$filter=updated_at gt '#{sync.updated_at.iso8601}'")
                expect(client).to receive(:get).with("/#{connec_name.downcase.pluralize}?#{uri_param}")
                subject.get_connec_entities(client, sync, organization)
              end
            end

            context 'with pagination' do
              before {
                allow(client).to receive(:get).and_return(ActionDispatch::Response.new(200, {}, {people: [], pagination: {next: "https://api-connec.maestrano.com/api/v2/cld-dkg601/people?%24skip=10&%24top=10"}}.to_json, {}), ActionDispatch::Response.new(200, {}, {people: []}.to_json, {}))
              }

              it 'calls get multiple times' do
                expect(client).to receive(:get).twice
                subject.get_connec_entities(client, nil, organization)
              end
            end

            context 'with an actual response' do
              let(:people) { [{first_name: 'John'}, {last_name: 'Durand'}, {job_title: 'Engineer'}] }

              it 'returns an array of entities' do
                allow(client).to receive(:get).and_return(ActionDispatch::Response.new(200, {}, {people: people}.to_json, {}))
                expect(subject.get_connec_entities(client, nil, organization)).to eql(JSON.parse(people.to_json))
              end
            end
          end
        end

        describe 'without response' do
          before {
            allow(client).to receive(:get).and_return(nil)
          }
          it { expect{ subject.get_connec_entities(client, nil, organization) }.to raise_error("No data received from Connec! when trying to fetch #{connec_name.pluralize}") }
        end
      end

      describe 'push_entities_to_connec' do
        it 'calls push_entities_to_connec_to' do
          allow(subject).to receive(:connec_entity_name).and_return(connec_name)
          expect(subject).to receive(:push_entities_to_connec_to).with(client, [{entity: {}, idmap: nil}], connec_name, nil)
          subject.push_entities_to_connec(client, [{entity: {}, idmap: nil}], nil)
        end
      end

      describe 'push_entities_to_connec_to' do
        let(:organization) { create(:organization) }
        let(:idmap1) { create(:idmap, organization: organization) }
        let(:idmap2) { create(:idmap, organization: organization, connec_id: nil, last_push_to_connec: nil) }
        let(:entity1) { {name: 'John'} }
        let(:entity2) { {name: 'Jane'} }
        let(:entity_with_idmap1) { {entity: entity1, idmap: idmap1} }
        let(:entity_with_idmap2) { {entity: entity2, idmap: idmap2} }
        let(:entities_with_idmaps) { [entity_with_idmap1, entity_with_idmap2] }
        let(:id) { 'ab12-34re' }

        context 'when read only' do
          before {
            allow(subject.class).to receive(:can_write_connec?).and_return(false)
          }

          it 'does nothing' do
            expect(subject).to_not receive(:create_connec_entity)
            expect(subject).to_not receive(:update_connec_entity)
            subject.push_entities_to_connec_to(client, entities_with_idmaps, connec_name, organization)
          end
        end

        context 'when create_only' do
          before {
            allow(subject.class).to receive(:can_update_connec?).and_return(false)
          }
          it 'calls create only' do
            expect(subject).to receive(:create_connec_entity).with(client, entity2, connec_name.downcase.pluralize, organization)
            expect(subject).to_not receive(:update_connec_entity)
            subject.push_entities_to_connec_to(client, entities_with_idmaps, connec_name, organization)
          end
        end

        it 'create or update the entities and idmaps according to their idmap state' do
          allow(subject).to receive(:create_connec_entity).and_return({'id' => id})
          allow(subject).to receive(:external_entity_name).and_return(external_name)

          expect(subject).to receive(:create_connec_entity).with(client, entity2, connec_name.downcase.pluralize, organization)
          expect(subject).to receive(:update_connec_entity).with(client, entity1, idmap1.connec_id, connec_name.downcase.pluralize, organization)
          old_push_date = idmap1.last_push_to_connec

          subject.push_entities_to_connec_to(client, entities_with_idmaps, connec_name, organization)

          idmap1.reload
          expect(idmap1.last_push_to_connec).to_not eql(old_push_date)
          idmap2.reload
          expect(idmap2.connec_id).to eql(id)
          expect(idmap2.last_push_to_connec).to_not be_nil
        end

        it 'stores an errr if any in the idmap' do
          subject.push_entities_to_connec_to(client, entities_with_idmaps, '', organization)
          idmap1.reload
          expect(idmap1.message).to_not be nil
        end
      end

      describe 'create_connec_entity' do
        let(:entity) { {name: 'John'} }

        before {
          allow(client).to receive(:post).and_return(ActionDispatch::Response.new(200, {}, {people: entity}.to_json, {}))
        }

        it 'sends a post to connec' do
          expect(client).to receive(:post).with("/#{connec_name.downcase.pluralize}", {"#{connec_name.downcase.pluralize}".to_sym => entity})
          subject.create_connec_entity(client, entity, connec_name.downcase.pluralize, organization)
        end

        it 'returns the created entity' do
          expect(subject.create_connec_entity(client, entity, connec_name.downcase.pluralize, organization)).to eql(JSON.parse(entity.to_json))
        end
      end

       describe 'update_connec_entity' do
        let(:organization) { create(:organization) }
        let(:entity) { {name: 'John'} }
        let(:id) { '88ye-777ab' }
        before {
          allow(client).to receive(:put).and_return(ActionDispatch::Response.new(200, {}, {}.to_json, {}))
        }

        it 'sends a put to connec' do
          expect(client).to receive(:put).with("/#{connec_name.downcase.pluralize}/#{id}", {"#{connec_name.downcase.pluralize}".to_sym => entity})
          subject.update_connec_entity(client, entity, id, connec_name.downcase.pluralize, organization)
        end
      end

      describe 'map_to_external_with_idmap' do
        let(:organization) { create(:organization) }
        let(:id) { '765e-zer4' }
        let(:mapped_entity) { {'first_name' => 'John'} }
        before {
          allow(subject.class).to receive(:connec_entity_name).and_return(connec_name)
          allow(subject.class).to receive(:external_entity_name).and_return(external_name)
          allow(subject).to receive(:map_to_external).and_return(mapped_entity)
          allow(subject.class).to receive(:object_name_from_connec_entity_hash).and_return('name')
          allow(subject.class).to receive(:object_name_from_external_entity_hash).and_return('name')
        }

        context 'when entity has an idmap' do
          let!(:idmap) { create(:idmap, organization: organization, external_entity: external_name.downcase, connec_entity: connec_name.downcase, connec_id: id, last_push_to_external: 3.hour.ago)}

          context 'when updated_at field is most recent than idmap last_push_to_external' do
            let(:entity) { {'id' => id, 'name' => 'John', 'updated_at' => 2.hour.ago } }

            it 'returns the entity with its idmap' do
              expect(subject.map_to_external_with_idmap(entity, organization)).to eql({entity: mapped_entity, idmap: idmap})
            end
          end

          context 'when updated_at field is older than idmap last_push_to_external' do
            let(:entity) { {'id' => id, 'name' => 'John', 'updated_at' => 5.hour.ago } }

            it 'discards the entity' do
              expect(subject.map_to_external_with_idmap(entity, organization)).to be_nil
            end
          end

          context 'when to_external is set to false' do
            let(:entity) { {'id' => id, 'name' => 'John' } }
            before {
              idmap.update(to_external: false)
            }

            it 'discards the entity' do
              expect(subject.map_to_external_with_idmap(entity, organization)).to be_nil
            end
          end
        end

        context 'when entity has no idmap' do
          let(:entity) { {'id' => id, 'name' => 'John', 'updated_at' => 5.hour.ago } }
          before {
            allow(subject.class).to receive(:object_name_from_connec_entity_hash).and_return('human readable stuff')
          }

          it { expect{ subject.map_to_external_with_idmap(entity, organization) }.to change{Maestrano::Connector::Rails::IdMap.count}.by(1) }

          it 'returns the entity with its new idmap' do
            expect(subject.map_to_external_with_idmap(entity, organization)).to eql({entity: mapped_entity, idmap: Maestrano::Connector::Rails::IdMap.last})
          end

          it 'save the entity name in the idmap' do
            subject.map_to_external_with_idmap(entity, organization)
            expect(Maestrano::Connector::Rails::IdMap.last.name).to eql('human readable stuff')
          end
        end
      end
    end


    # External methods
    describe 'external methods' do
      let(:organization) { create(:organization) }
      let(:connec_name) { 'connec_name' }
      let(:external_name) { 'external_name' }
      let(:idmap1) { create(:idmap, organization: organization) }
      let(:idmap2) { create(:idmap, organization: organization, external_id: nil, external_entity: nil, last_push_to_external: nil) }
      let(:entity1) { {name: 'John'} }
      let(:entity2) { {name: 'Jane'} }
      let(:entity_with_idmap1) { {entity: entity1, idmap: idmap1} }
      let(:entity_with_idmap2) { {entity: entity2, idmap: idmap2} }
      let(:entities_with_idmaps) { [entity_with_idmap1, entity_with_idmap2] }

      describe 'get_external_entities' do
        it { expect{ subject.get_external_entities(nil, nil, organization) }.to raise_error('Not implemented') }
      end

      describe 'push_entities_to_external' do
        it 'calls push_entities_to_external_to' do
          allow(subject.class).to receive(:external_entity_name).and_return(external_name)
          expect(subject).to receive(:push_entities_to_external_to).with(nil, entities_with_idmaps, external_name, organization)
          subject.push_entities_to_external(nil, entities_with_idmaps, organization)
        end
      end

      describe 'push_entities_to_external_to' do
        context 'when read only' do
          it 'does nothing' do
            allow(subject.class).to receive(:can_write_external?).and_return(false)
            expect(subject).to_not receive(:push_entity_to_external)
            subject.push_entities_to_external_to(nil, entities_with_idmaps, external_name, organization)
          end
        end

        it 'calls push_entity_to_external for each entity' do
          allow(subject.class).to receive(:connec_entity_name).and_return(connec_name)
          expect(subject).to receive(:push_entity_to_external).twice
          subject.push_entities_to_external_to(nil, entities_with_idmaps, external_name, organization)
        end
      end

      describe 'push_entity_to_external' do
        context 'when the entity idmap has an external id' do
          it 'does not calls update if create_only' do
            allow(subject.class).to receive(:can_update_external?).and_return(false)
            expect(subject).to_not receive(:update_external_entity)
            subject.push_entity_to_external(nil, entity_with_idmap1, external_name, organization)
          end

          it 'calls update_external_entity' do
            expect(subject).to receive(:update_external_entity).with(nil, entity1, idmap1.external_id, external_name, organization)
            subject.push_entity_to_external(nil, entity_with_idmap1, external_name, organization)
          end

          it 'updates the idmap last push to external' do
            allow(subject).to receive(:update_external_entity)
            time_before = idmap1.last_push_to_external
            subject.push_entity_to_external(nil, entity_with_idmap1, external_name, organization)
            idmap1.reload
            expect(idmap1.last_push_to_external).to_not eql(time_before)
          end
        end

        context 'when the entity idmap does not have an external id' do
          it 'calls create_external_entity' do
            expect(subject).to receive(:create_external_entity).with(nil, entity2, external_name, organization)
            subject.push_entity_to_external(nil, entity_with_idmap2, external_name, organization)
          end

          it 'updates the idmap external id, entity and last push' do
            allow(subject).to receive(:create_external_entity).and_return('999111')
            subject.push_entity_to_external(nil, entity_with_idmap2, external_name, organization)
            idmap2.reload
            expect(idmap2.external_id).to eql('999111')
            expect(idmap2.last_push_to_external).to_not be_nil
          end
        end
      end

      describe 'create_external_entity' do
        let(:organization) { create(:organization) }

        it { expect{ subject.create_external_entity(nil, nil, nil, organization) }.to raise_error('Not implemented') }
      end

      describe 'update_external_entity' do
        let(:organization) { create(:organization) }

        it { expect{ subject.update_external_entity(nil, nil, nil, nil, organization) }.to raise_error('Not implemented') }
      end
    end


    # General methods
    describe 'consolidate_and_map_data' do
      let(:organization) { create(:organization) }
      let(:external_name) { 'External_name' }
      let(:connec_name) { 'Connec_name' }
      let(:id) { '56882' }
      let(:date) { 2.hour.ago }
      before {
        allow(subject.class).to receive(:id_from_external_entity_hash).and_return(id)
        allow(subject.class).to receive(:last_update_date_from_external_entity_hash).and_return(date)
        allow(subject.class).to receive(:external_entity_name).and_return(external_name)
        allow(subject.class).to receive(:connec_entity_name).and_return(connec_name)
      }

      context 'for a singleton method' do
        before {
          allow(subject.class).to receive(:singleton?).and_return(true)
          allow(subject).to receive(:map_to_connec).and_return({map: 'connec'})
          allow(subject).to receive(:map_to_external).and_return({map: 'external'})
          allow(subject.class).to receive(:object_name_from_connec_entity_hash).and_return('connec human name')
          allow(subject.class).to receive(:object_name_from_external_entity_hash).and_return('external human name')
        }

        it { expect(subject.consolidate_and_map_data([], [], organization)).to eql({connec_entities: [], external_entities: []}) }

        context 'with no idmap' do
          it 'creates one for connec' do
            subject.consolidate_and_map_data([{'id' => 'lala'}], [], organization)
            idmap = Maestrano::Connector::Rails::IdMap.last
            expect(idmap.connec_entity).to eql(connec_name.downcase)
            expect(idmap.external_entity).to eql(external_name.downcase)
            expect(idmap.connec_id).to eql('lala')
          end

          it 'creates one for external' do
            subject.consolidate_and_map_data([], [{}], organization)
            idmap = Maestrano::Connector::Rails::IdMap.last
            expect(idmap.connec_entity).to eql(connec_name.downcase)
            expect(idmap.external_entity).to eql(external_name.downcase)
            expect(idmap.external_id).to eql(id)
          end
        end

        context 'with an idmap' do
          let!(:idmap) { create(:idmap, connec_entity: connec_name.downcase, external_entity: external_name.downcase, organization: organization) }

          it { expect{ subject.consolidate_and_map_data([{}], [], organization) }.to_not change{ Maestrano::Connector::Rails::IdMap } }
        end

        context 'with conflict' do
          let!(:idmap) { create(:idmap, connec_entity: connec_name.downcase, external_entity: external_name.downcase, organization: organization, external_id: id, connec_id: 'lala') }
          let(:updated) { 3.hour.ago }
          let(:connec_entity) { {'id' => 'lala', 'updated_at' => updated} }

          context 'with options' do
            it { expect(subject.consolidate_and_map_data([connec_entity], [{}], organization, connec_preemption: true)).to eql({connec_entities: [{entity: {map: 'external'}, idmap: idmap}], external_entities: []}) }
            it { expect(subject.consolidate_and_map_data([connec_entity], [{}], organization, connec_preemption: false)).to eql({connec_entities: [], external_entities: [{entity: {map: 'connec'}, idmap: idmap}]}) }
          end

          context 'without options' do
            context 'with a more recent external one' do
              it { expect(subject.consolidate_and_map_data([connec_entity], [{}], organization)).to eql({connec_entities: [], external_entities: [{entity: {map: 'connec'}, idmap: idmap}]}) }
            end
            context 'with a more recent connec one' do
              let(:updated) { 2.minute.ago }
              it { expect(subject.consolidate_and_map_data([connec_entity], [{}], organization)).to eql({connec_entities: [{entity: {map: 'external'}, idmap: idmap}], external_entities: []}) }
            end
          end
        end
      end

      context 'for a non singleton method' do

        describe 'connec_entities treatment' do
          let(:entity1) { {name: 'John'} }
          let(:entity2) { {name: 'Jane'} }

          it 'calls map_to_external_with_idmap for each entity' do
            expect(subject).to receive(:map_to_external_with_idmap).with(entity1, organization)
            expect(subject).to receive(:map_to_external_with_idmap).with(entity2, organization)
            subject.consolidate_and_map_data([entity1, entity2], [], organization)
          end
        end

        describe 'external_entities treatment' do
          let(:entity) { {id: id, name: 'John', modifiedDate: date} }
          let(:mapped_entity) { {first_name: 'John'} }
          let(:entities) { [entity] }
          let(:human_name) { 'alien' }

          before {
            allow(subject).to receive(:map_to_connec).and_return(mapped_entity)
            allow(subject.class).to receive(:object_name_from_external_entity_hash).and_return(human_name)
          }

          context 'when entity has no idmap' do

            it 'creates an idmap and returns the mapped entity with its new idmap' do
              mapped_entities = subject.consolidate_and_map_data([], entities, organization)
              expect(mapped_entities).to eql({connec_entities: [], external_entities: [{entity: mapped_entity, idmap: Maestrano::Connector::Rails::IdMap.last}]})
            end

            it 'save the name in the idmap' do
              subject.consolidate_and_map_data([], entities, organization)
              expect(Maestrano::Connector::Rails::IdMap.last.name).to eql(human_name)
            end
          end

          context 'when entity has an idmap with to_connec set to false' do
            let!(:idmap) { create(:idmap, external_entity: external_name.downcase, connec_entity: connec_name.downcase, external_id: id, organization: organization, to_connec: false) }
            it 'discards the entity' do
              mapped_entities = subject.consolidate_and_map_data([], entities, organization)
              expect(mapped_entities).to eql({connec_entities: [], external_entities: []})
            end
          end

          context 'when entity has an idmap with a last_push_to_connec more recent than date' do
            let!(:idmap) { create(:idmap, connec_entity: connec_name.downcase, external_entity: external_name.downcase, external_id: id, organization: organization, last_push_to_connec: 2.minute.ago) }

            it 'discards the entity' do
              mapped_entities = subject.consolidate_and_map_data([], entities, organization)
              expect(mapped_entities).to eql({connec_entities: [], external_entities: []})
            end
          end

          context 'when entity has an idmap with a last_push_to_connec older than date' do

            context 'with no conflict' do
              let!(:idmap) { create(:idmap, connec_entity: connec_name.downcase, external_entity: external_name.downcase, external_id: id, organization: organization, last_push_to_connec: 2.day.ago) }

              it 'returns the mapped entity with its idmap' do
                mapped_entities = subject.consolidate_and_map_data([], entities, organization)
                expect(mapped_entities).to eql({connec_entities: [], external_entities: [{entity: mapped_entity, idmap: idmap}]})
              end
            end

            context 'with conflict' do
              let(:connec_id) { '34uuu-778aa' }
              let!(:idmap) { create(:idmap, connec_id: connec_id, connec_entity: connec_name.downcase, external_entity: external_name.downcase, external_id: id, organization: organization, last_push_to_connec: 2.day.ago) }
              before {
                allow(subject).to receive(:map_to_external_with_idmap)
              }

              context 'with connec_preemption opt' do

                context 'set to true' do
                  let(:connec_entity) { {'id' => connec_id, 'first_name' => 'Richard', 'updated_at' => 1.day.ago} }
                  it 'discards the entity' do
                    mapped_entities = subject.consolidate_and_map_data([connec_entity], entities, organization, {connec_preemption: true})
                    expect(mapped_entities).to eql({connec_entities: [], external_entities: []})
                  end
                end

                context 'set to false' do
                  let(:connec_entity) { {'id' => connec_id, 'first_name' => 'Richard', 'updated_at' => 1.second.ago} }
                  it 'returns the mapped entity with its idmap' do
                    mapped_entities = subject.consolidate_and_map_data([connec_entity], entities, organization, {connec_preemption: false})
                    expect(mapped_entities).to eql({connec_entities: [], external_entities: [{entity: mapped_entity, idmap: idmap}]})
                  end
                end
              end

              context 'without opt' do
                context 'with a more recent connec entity' do
                  let(:connec_entity) { {'id' => connec_id, 'first_name' => 'Richard', 'updated_at' => 1.second.ago} }

                  it 'discards the entity' do
                    mapped_entities = subject.consolidate_and_map_data([connec_entity], entities, organization, {connec_preemption: true})
                    expect(mapped_entities).to eql({connec_entities: [], external_entities: []})
                  end
                end

                context 'with a more recent external_entity' do
                  let(:connec_entity) { {'id' => connec_id, 'first_name' => 'Richard', 'updated_at' => 1.year.ago} }

                  it 'returns the mapped entity with its idmap' do
                    mapped_entities = subject.consolidate_and_map_data([connec_entity], entities, organization, {connec_preemption: false})
                    expect(mapped_entities).to eql({connec_entities: [], external_entities: [{entity: mapped_entity, idmap: idmap}]})
                  end
                end
              end

            end
          end

        end

      end
    end
  end

end