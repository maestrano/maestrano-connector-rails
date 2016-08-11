require 'spec_helper'

describe Maestrano::Connector::Rails::Entity do

  describe 'class methods' do
    subject { Maestrano::Connector::Rails::Entity }

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

      it {
        expect(Maestrano::Connector::Rails::IdMap).to receive(:create).with(n_hash.merge(id: 'lala'))
        subject.create_idmap({id: 'lala'})
      }
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

    describe 'creation_date_from_external_entity_hash' do
      it { expect{ subject.creation_date_from_external_entity_hash(nil) }.to raise_error('Not implemented') }
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

    describe 'connec_matching_fields' do
      it { expect(subject.connec_matching_fields).to be_nil }
    end

    describe 'count_and_first' do
      it 'returns the array size and the first element' do
        expect(subject.count_and_first([*1..27])).to eql(count: 27, first: 1)
      end
    end

    describe 'public_connec_entity_name' do
      it 'returns the pluralized connec_entity_name' do
        allow(subject).to receive(:connec_entity_name).and_return('tree')
        expect(subject.public_connec_entity_name).to eql('trees')
      end

      context 'when singleton' do
        before {
          allow(subject).to receive(:singleton?).and_return(true)
        }

        it 'returns the connec_entity_name' do
          allow(subject).to receive(:connec_entity_name).and_return('tree')
          expect(subject.public_connec_entity_name).to eql('tree')
        end
      end
    end

    describe 'public_external_entity_name' do
      it 'returns the pluralized external_entity_name' do
        allow(subject).to receive(:external_entity_name).and_return('tree')
        expect(subject.public_external_entity_name).to eql('trees')
      end
    end
  end

  describe 'instance methods' do
    let!(:organization) { create(:organization, uid: 'cld-123') }
    let!(:connec_client) { Maestrano::Connec::Client[organization.tenant].new(organization.uid) }
    let!(:external_client) { Object.new }
    let(:opts) { {} }
    subject { Maestrano::Connector::Rails::Entity.new(organization, connec_client, external_client, opts) }
    let(:connec_name) { 'Person' }
    let(:external_name) { 'external_name' }
    before {
      allow(subject.class).to receive(:connec_entity_name).and_return(connec_name)
      allow(subject.class).to receive(:external_entity_name).and_return(external_name)
    }

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
          subject.map_to_external({})
        end
      end

      describe 'map_to_connec' do
        before {
          allow(subject.class).to receive(:id_from_external_entity_hash).and_return('this id')
        }
        it 'calls the mapper denormalize' do
          expect(AMapper).to receive(:denormalize).with({}).and_return({})
          subject.map_to_connec({})
        end

        it 'calls for reference folding' do
          refs = %w(organization_id person_id)
          allow(subject.class).to receive(:references).and_return(refs)
          expect(Maestrano::Connector::Rails::ConnecHelper).to receive(:fold_references).with({id: 'this id'}, refs, organization)
          subject.map_to_connec({})
        end

        it 'merges the smart merging options' do
          allow(AMapper).to receive(:denormalize).and_return({opts: {some_opt: 4}})
          allow(subject.class).to receive(:connec_matching_fields).and_return([['first_name'], ['last_name']])
          expect(subject.map_to_connec({})).to eql({id: [{id: 'this id', provider: organization.oauth_provider, realm: organization.oauth_uid}], opts: {some_opt: 4, matching_fields: [['first_name'], ['last_name']]}}.with_indifferent_access)
        end
      end
    end

    # Connec! methods
    describe 'connec_methods' do
      let(:sync) { create(:synchronization, organization: organization) }

      describe 'filter_connec_entities' do
        it 'does nothing by default' do
          expect(subject.filter_connec_entities({a: 2})).to eql({a: 2})
        end
      end

      describe 'get_connec_entities' do
        describe 'when write only' do
          before {
            allow(subject.class).to receive(:can_read_connec?).and_return(false)
            allow(connec_client).to receive(:get).and_return(ActionDispatch::Response.new(200, {}, {people: [{first_name: 'Lea'}]}.to_json, {}))
          }

          it { expect(subject.get_connec_entities(nil)).to eql([]) }
        end

        describe 'when skip_connec' do
          let(:opts) { {__skip_connec: true} }
          it { expect(subject.get_connec_entities(nil)).to eql([]) }
        end

        describe 'with response' do
          context 'for a singleton resource' do
            before {
              allow(connec_client).to receive(:get).and_return(ActionDispatch::Response.new(200, {}, {person: []}.to_json, {}))
              allow(subject.class).to receive(:singleton?).and_return(true)
            }

            it 'calls get with a singularize url' do
              expect(connec_client).to receive(:get).with("#{connec_name.downcase}?")
              subject.get_connec_entities(nil)
            end
          end

          context 'for a non singleton resource' do
            before {
              allow(connec_client).to receive(:get).and_return(ActionDispatch::Response.new(200, {}, {people: []}.to_json, {}))
            }

            context 'with limit and skip opts' do
              let(:opts) { {__skip: 100, __limit: 50} }
              before {
                allow(connec_client).to receive(:get).and_return(ActionDispatch::Response.new(200, {}, {people: [], pagination: {next: "https://api-connec.maestrano.com/api/v2/cld-dkg601/people?%24skip=10&%24top=10"}}.to_json, {}), ActionDispatch::Response.new(200, {}, {people: []}.to_json, {}))
              }

              it 'performs a size limited date and do not paginate' do
                uri_param = {"$filter" => "updated_at gt '#{sync.updated_at.iso8601}'", "$skip" => 100, "$top" => 50}.to_query
                expect(connec_client).to receive(:get).once.with("#{connec_name.downcase.pluralize}?#{uri_param}")
                subject.get_connec_entities(sync.updated_at)
              end
            end

            context 'when opts[:full_sync] is true' do
              let(:opts) { {full_sync: true} }
              it 'performs a full get' do
                expect(connec_client).to receive(:get).with("#{connec_name.downcase.pluralize}?")
                subject.get_connec_entities(sync.updated_at)
              end
            end

            context 'when there is no last sync' do
              it 'performs a full get' do
                expect(connec_client).to receive(:get).with("#{connec_name.downcase.pluralize}?")
                subject.get_connec_entities(nil)
              end
            end

            context 'when there is a last sync' do
              it 'performs a time limited get' do
                uri_param = {"$filter" => "updated_at gt '#{sync.updated_at.iso8601}'"}.to_query
                expect(connec_client).to receive(:get).with("#{connec_name.downcase.pluralize}?#{uri_param}")
                subject.get_connec_entities(sync.updated_at)
              end
            end

            context 'with options' do
              it 'support filter option for full sync' do
                subject.instance_variable_set(:@opts, {full_sync: true, :$filter => "code eq 'PEO12'"})
                uri_param = {'$filter'=>'code eq \'PEO12\''}.to_query
                expect(connec_client).to receive(:get).with("#{connec_name.downcase.pluralize}?#{uri_param}")
                subject.get_connec_entities(sync.updated_at)
              end

              it 'support filter option for time limited sync' do
                subject.instance_variable_set(:@opts, {:$filter => "code eq 'PEO12'"})
                uri_param = {"$filter"=>"updated_at gt '#{sync.updated_at.iso8601}' and code eq 'PEO12'"}.to_query
                expect(connec_client).to receive(:get).with("#{connec_name.downcase.pluralize}?#{uri_param}")
                subject.get_connec_entities(sync.updated_at)
              end

              it 'support orderby option for time limited sync' do
                subject.instance_variable_set(:@opts, {:$orderby => "name asc"})
                uri_param = {"$orderby"=>"name asc", "$filter"=>"updated_at gt '#{sync.updated_at.iso8601}'"}.to_query
                expect(connec_client).to receive(:get).with("#{connec_name.downcase.pluralize}?#{uri_param}")
                subject.get_connec_entities(sync.updated_at)
              end
            end

            context 'with pagination' do
              before {
                allow(connec_client).to receive(:get).and_return(ActionDispatch::Response.new(200, {}, {people: [], pagination: {next: "https://api-connec.maestrano.com/api/v2/cld-dkg601/people?%24skip=10&%24top=10"}}.to_json, {}), ActionDispatch::Response.new(200, {}, {people: []}.to_json, {}))
              }

              it 'calls get multiple times' do
                expect(connec_client).to receive(:get).with('people?')
                expect(connec_client).to receive(:get).with('people?%24skip=10&%24top=10')
                subject.get_connec_entities(nil)
              end
            end

            context 'with an actual response' do
              let(:people) { [{first_name: 'John'}, {last_name: 'Durand'}, {job_title: 'Engineer'}] }

              it 'returns an array of entities' do
                allow(connec_client).to receive(:get).and_return(ActionDispatch::Response.new(200, {}, {people: people}.to_json, {}))
                expect(subject.get_connec_entities(nil)).to eql(JSON.parse(people.to_json))
              end
            end
          end
        end

        describe 'failures' do
          context 'when no response' do
            before {
              allow(connec_client).to receive(:get).and_return(ActionDispatch::Response.new(200, {}, nil, {}))
            }
            it { expect{ subject.get_connec_entities(nil) }.to raise_error(RuntimeError) }
          end

          context 'when invalid response' do
            before {
              allow(connec_client).to receive(:get).and_return(ActionDispatch::Response.new(200, {}, {not_an_entity: []}.to_json, {}))
            }
            it { expect{ subject.get_connec_entities(nil) }.to raise_error(RuntimeError) }
          end

          context 'when no response in pagination' do
            before {
              allow(connec_client).to receive(:get).and_return(ActionDispatch::Response.new(200, {}, {people: [], pagination: {next: "https://api-connec.maestrano.com/api/v2/cld-dkg601/people?%24skip=10&%24top=10"}}.to_json, {}), ActionDispatch::Response.new(200, {}, nil, {}))
            }
            it { expect{ subject.get_connec_entities(nil) }.to raise_error(RuntimeError) }
          end

          context 'when invalid response in pagination' do
            before {
              allow(connec_client).to receive(:get).and_return(ActionDispatch::Response.new(200, {}, {people: [], pagination: {next: "https://api-connec.maestrano.com/api/v2/cld-dkg601/people?%24skip=10&%24top=10"}}.to_json, {}), ActionDispatch::Response.new(200, {}, {not_an_entity: []}.to_json, {}))
            }
            it { expect{ subject.get_connec_entities(nil) }.to raise_error(RuntimeError) }
          end
        end
      end

      describe 'push_entities_to_connec' do
        it 'calls push_entities_to_connec_to' do
          expect(subject).to receive(:push_entities_to_connec_to).with([{entity: {}, idmap: nil}], connec_name)
          subject.push_entities_to_connec([{entity: {}, idmap: nil}])
        end
      end

      describe 'push_entities_to_connec_to' do
        let(:idmap1) { create(:idmap, organization: organization) }
        let(:idmap2) { create(:idmap, organization: organization, connec_id: nil) }
        let(:entity1) { {name: 'John'} }
        let(:entity2) { {name: 'Jane'} }
        let(:entity_with_idmap1) { {entity: entity1, idmap: idmap1} }
        let(:entity_with_idmap2) { {entity: entity2, idmap: idmap2} }
        let(:entities_with_idmaps) { [entity_with_idmap1, entity_with_idmap2] }

        context 'when read only' do
          before {
            allow(subject.class).to receive(:can_write_connec?).and_return(false)
          }

          it 'does nothing' do
            expect(subject).to_not receive(:batch_op)
            subject.push_entities_to_connec_to(entities_with_idmaps, connec_name)
          end
        end

        context 'when no update' do
          before {
            allow(subject.class).to receive(:can_update_connec?).and_return(false)
            allow(connec_client).to receive(:batch).and_return(ActionDispatch::Response.new(200, {}, {results: []}.to_json, {}))
          }

          it 'filters out the one with a connec_id' do
            expect(subject).to receive(:batch_op).once.with('post', entity2, nil, 'people')
            subject.push_entities_to_connec_to(entities_with_idmaps, connec_name)
          end
        end

        context 'without errors' do
          let(:result200) { {status: 200, body: {connec_name.downcase.pluralize.to_sym => {id: [{provider: 'connec', id: 'id1'}]}}} }
          let(:result201) { {status: 201, body: {connec_name.downcase.pluralize.to_sym => {id: [{provider: 'connec', id: 'id2'}]}}} }
          before {
            allow(connec_client).to receive(:batch).and_return(ActionDispatch::Response.new(200, {}, {results: [result200, result201]}.to_json, {}))
          }

          let(:batch_request) {
            {
              sequential: true,
              ops: [
                {
                  :method=>"post",
                  :url=>"/api/v2/cld-123/people/",
                  :params=>{:people=>{:name=>"John"}}
                },
                {
                  :method=>"post",
                  :url=>"/api/v2/cld-123/people/",
                  :params=>{:people=>{:name=>"Jane"}}
                }
              ]
            }
          }

          it 'calls batch op' do
            expect(subject).to receive(:batch_op).twice
            subject.push_entities_to_connec_to(entities_with_idmaps, connec_name)
          end

          it 'creates a batch request' do
            expect(connec_client).to receive(:batch).with(batch_request)
            subject.push_entities_to_connec_to(entities_with_idmaps, connec_name)
          end

          it 'update the idmaps push dates' do
            old_push_date = idmap1.last_push_to_connec

            subject.push_entities_to_connec_to(entities_with_idmaps, connec_name)

            idmap1.reload
            expect(idmap1.last_push_to_connec).to_not eql(old_push_date)
            idmap2.reload
            expect(idmap2.last_push_to_connec).to_not be_nil
          end

          describe 'batch batch calls' do
            let(:entities) { [] }
            let(:results) { [] }

            context 'when 100 entities' do
              before {
                100.times do
                  entities << entity_with_idmap1
                  results << result200
                end
                allow(connec_client).to receive(:batch).and_return(ActionDispatch::Response.new(200, {}, {results: results}.to_json, {}))
              }

              it 'does one call' do
                expect(connec_client).to receive(:batch).once
                subject.push_entities_to_connec_to(entities, connec_name)
              end              
            end

            context 'when more than 100 entities' do
              before {
                100.times do
                  entities << entity_with_idmap1
                  results << result200
                end
                entities << entity_with_idmap2
                allow(connec_client).to receive(:batch).and_return(ActionDispatch::Response.new(200, {}, {results: results}.to_json, {}), ActionDispatch::Response.new(200, {}, {results: [result201]}.to_json, {}))
              }

              it 'does several call' do
                expect(connec_client).to receive(:batch).twice
                subject.push_entities_to_connec_to(entities, connec_name)
              end

              it 'updates the idmap push dates' do
                subject.push_entities_to_connec_to(entities, connec_name)
                idmap2.reload
                expect(idmap2.last_push_to_connec).to_not be_nil
              end
            end
          end
        end

        context 'with errors' do
          let(:err_msg) { 'Not Found' }
          let(:result400) { {status: 400, body: err_msg} }
          before {
            allow(connec_client).to receive(:batch).and_return(ActionDispatch::Response.new(200, {}, {results: [result400, result400]}.to_json, {}))
          }

          it 'stores the errr in the idmap' do
            subject.push_entities_to_connec_to(entities_with_idmaps, '')
            idmap2.reload
            expect(idmap2.message).to eq result400[:body]
          end

          context 'with a long error message' do
            let(:err_msg) { 'A very long sentence with a lot of error or more likely a badly designed API that return an html 404 page instead of a nice json answer an then the world is sad and the kitten are unhappy. So juste to be safe we are truncating the error message and I am running out of words to write I hope it is long enough' }
            it 'truncates the error message' do
              subject.push_entities_to_connec_to(entities_with_idmaps, '')
              idmap2.reload
              expect(idmap2.message).to eq err_msg.truncate(255)
            end
          end
        end
      end
    end

    # External methods
    describe 'external methods' do
      before {
        allow(subject.class).to receive(:id_from_external_entity_hash).and_return('id')
      }
      let(:idmap1) { create(:idmap, organization: organization) }
      let(:idmap2) { create(:idmap, organization: organization, external_id: nil, external_entity: nil, last_push_to_external: nil) }
      let(:entity1) { {name: 'John'} }
      let(:entity2) { {name: 'Jane'} }
      let(:id_refs_only_connec_entity1) { {} }
      let(:id_refs_only_connec_entity2) { {} }
      let(:entity_with_idmap1) { {entity: entity1, idmap: idmap1, id_refs_only_connec_entity: id_refs_only_connec_entity1} }
      let(:connec_id2) { 'connec_id2' }
      let(:entity_with_idmap2) { {entity: entity2, idmap: idmap2, id_refs_only_connec_entity: id_refs_only_connec_entity2} }
      let(:entities_with_idmaps) { [entity_with_idmap1, entity_with_idmap2] }

      describe 'get_external_entities_wrapper' do
        context 'when write only' do
          before { allow(subject.class).to receive(:can_read_external?).and_return(false) }

          it 'returns an empty array and does not call get_external_entities' do
            expect(subject).to_not receive(:get_connec_entities)
            expect(subject.get_external_entities_wrapper(nil)).to eql([])
          end
        end

        context 'when skip external' do
          let(:opts) { {__skip_external: true} }

          it 'returns an empty array and does not call get_external_entities' do
            expect(subject).to_not receive(:get_connec_entities)
            expect(subject.get_external_entities_wrapper(nil)).to eql([])
          end
        end

        it 'calls get_external_entities' do
          expect(subject).to receive(:get_external_entities).and_return([])
          subject.get_external_entities_wrapper(nil)
        end
      end

      describe 'get_external_entities' do
        it { expect{ subject.get_external_entities('') }.to raise_error('Not implemented') }
      end

      describe 'push_entities_to_external' do
        it 'calls push_entities_to_external_to' do
          expect(subject).to receive(:push_entities_to_external_to).with(entities_with_idmaps, external_name)
          subject.push_entities_to_external(entities_with_idmaps)
        end
      end

      describe 'push_entities_to_external_to' do
        context 'when read only' do
          it 'does nothing' do
            allow(subject.class).to receive(:can_write_external?).and_return(false)
            expect(subject).to_not receive(:push_entity_to_external)
            subject.push_entities_to_external_to(entities_with_idmaps, external_name)
          end
        end

        it 'calls push_entity_to_external for each entity' do
          expect(subject).to receive(:push_entity_to_external).twice
          subject.push_entities_to_external_to(entities_with_idmaps, external_name)
        end

        describe 'ids' do
          before {
            allow(subject.class).to receive(:id_from_external_entity_hash).and_return('id')
            allow(subject).to receive(:create_external_entity).and_return({'id' => 'id'})
            allow(subject).to receive(:update_external_entity).and_return(nil)
          }

          context 'when ids to send to connec' do
            let(:batch_param) {
              {:sequential=>true, :ops=>[{:method=>"put", :url=>"/api/v2/cld-123/people/#{idmap2.connec_id}", :params=>{:people=>{id: [{:id=>"id", :provider=>organization.oauth_provider, :realm=>organization.oauth_uid}]}}}]}
            }

            it 'does a batch call on connec' do
              expect(connec_client).to receive(:batch).with(batch_param).and_return(ActionDispatch::Response.new(200, {}, {results: []}.to_json, {}))
              subject.push_entities_to_external_to(entities_with_idmaps, external_name)
            end
          end

          context 'when no id to send to connec' do
            before {
              idmap2.update(external_id: 'id')
            }

            it 'does not do a call on connec' do
              expect(connec_client).to_not receive(:batch)
              subject.push_entities_to_external_to(entities_with_idmaps, external_name)
            end
          end
        end

        describe 'id_references' do
          let(:connec_line_id1) { 'connec_line_id1' }
          let(:connec_line_id2) { 'connec_line_id2' }
          let(:ext_line_id1) { 'ext_line_id1' }
          let(:ext_line_id2) { 'ext_line_id2' }
          let(:id_refs_only_connec_entity1) { {lines: [{id: [{provider: 'connec', realm: 'org', id: connec_line_id1}]}]}.with_indifferent_access }
          let(:id_refs_only_connec_entity2) { {lines: [{id: [{provider: 'connec', realm: 'org', id: connec_line_id2}]}]}.with_indifferent_access }
          before {
            allow(subject.class).to receive(:id_from_external_entity_hash).and_return('id')
            allow(subject.class).to receive(:references).and_return({record_references: [], id_references: ['lines/id']})
            allow(subject).to receive(:create_external_entity).and_return({'id' => 'id', invoice_lines: [{ID: ext_line_id1}]})
            allow(subject).to receive(:update_external_entity).and_return({'id' => 'id', invoice_lines: [{ID: ext_line_id2}]})
            allow(subject).to receive(:map_to_connec).and_return({lines: [{id: [{id: ext_line_id1, provider: organization.oauth_provider, realm: organization.oauth_uid}]}]}, {lines: [{id: [{id: ext_line_id2, provider: organization.oauth_provider, realm: organization.oauth_uid}]}]})
          }
          let(:batch_param) {
            {
              :sequential=>true,
              :ops=> [
                {
                  :method=>"put",
                  :url=>"/api/v2/cld-123/people/#{idmap1.connec_id}",
                  :params=>{:people=>{id: [{:id=>idmap1.external_id, :provider=>organization.oauth_provider, :realm=>organization.oauth_uid}], lines: [{id: [{provider: 'connec', realm: 'org', id: connec_line_id1}, {id: ext_line_id1, provider: organization.oauth_provider, realm: organization.oauth_uid}]}]}.with_indifferent_access}
                },
                {
                  :method=>"put",
                  :url=>"/api/v2/cld-123/people/#{idmap2.connec_id}",
                  :params=>{:people=>{id: [{:id=>'id', :provider=>organization.oauth_provider, :realm=>organization.oauth_uid}], lines: [{id: [{provider: 'connec', realm: 'org', id: connec_line_id2}, {id: ext_line_id2, provider: organization.oauth_provider, realm: organization.oauth_uid}]}]}.with_indifferent_access}
                }
              ]
            }
          }

          it 'send both the id and the id references to connec' do
            expect(connec_client).to receive(:batch).with(batch_param).and_return(ActionDispatch::Response.new(200, {}, {results: []}.to_json, {}))
            subject.push_entities_to_external_to(entities_with_idmaps, external_name)
          end
        end
      end

      describe 'push_entity_to_external' do
        context 'when the entity idmap has an external id' do
          it 'does not calls update if create_only' do
            allow(subject.class).to receive(:can_update_external?).and_return(false)
            expect(subject).to_not receive(:update_external_entity)
            expect(subject.push_entity_to_external(entity_with_idmap1, external_name)).to be_nil
          end

          it 'calls update_external_entity' do
            expect(subject).to receive(:update_external_entity).with(entity1, idmap1.external_id, external_name)
            subject.push_entity_to_external(entity_with_idmap1, external_name)
          end

          it 'updates the idmap last push to external' do
            allow(subject).to receive(:update_external_entity)
            time_before = idmap1.last_push_to_external
            expect(subject.push_entity_to_external(entity_with_idmap1, external_name)).to be_nil
            idmap1.reload
            expect(idmap1.last_push_to_external).to_not eql(time_before)
          end
        end

        context 'when the entity idmap does not have an external id' do
          it 'calls create_external_entity' do
            expect(subject).to receive(:create_external_entity).with(entity2, external_name)
            subject.push_entity_to_external(entity_with_idmap2, external_name)
          end

          it 'updates the idmap external id, entity and last push' do
            allow(subject).to receive(:create_external_entity).and_return({'id' => '999111'})
            allow(subject.class).to receive(:id_from_external_entity_hash).and_return('999111')
            subject.push_entity_to_external(entity_with_idmap2, external_name)
            idmap2.reload
            expect(idmap2.external_id).to eql('999111')
            expect(idmap2.last_push_to_external).to_not be_nil
          end

          it 'returns the idmap' do
            allow(subject).to receive(:create_external_entity).and_return({'id' => '999111'})
            allow(subject.class).to receive(:id_from_external_entity_hash).and_return('999111')
            expect(subject.push_entity_to_external(entity_with_idmap2, external_name)).to eql({idmap: idmap2, completed_hash: nil})
          end
        end

        describe 'failures' do

          it 'stores the error in the idmap' do
            allow(subject).to receive(:create_external_entity).and_raise('Kabooooom')
            allow(subject).to receive(:update_external_entity).and_raise('Kabooooom')
            subject.push_entity_to_external(entity_with_idmap1, external_name)
            subject.push_entity_to_external(entity_with_idmap2, external_name)
            expect(idmap1.reload.message).to include('Kabooooom')
            expect(idmap2.reload.message).to include('Kabooooom')
          end

          it 'truncates the message' do
            msg = 'Large corporations use our integrated platform to provide a fully customized environment to their clients, increasing revenue, engagement and gaining insight on client behavior through our Big Data technology. Large corporations use our integrated platform to provide a fully customized environment to their clients, increasing revenue, engagement and gaining insight on client behavior through our Big Data technology.'
            allow(subject).to receive(:create_external_entity).and_raise(msg)
            subject.push_entity_to_external(entity_with_idmap2, external_name)
            expect(idmap2.reload.message).to include(msg.truncate(255))
          end
        end
      end

      describe 'create_external_entity' do
        let(:organization) { create(:organization) }

        it { expect{ subject.create_external_entity(nil, nil) }.to raise_error('Not implemented') }
      end

      describe 'update_external_entity' do
        let(:organization) { create(:organization) }

        it { expect{ subject.update_external_entity(nil, nil, nil) }.to raise_error('Not implemented') }
      end
    end

    describe 'consolidate_and_map methods' do
      let(:id) { '56882' }
      let(:date) { 2.hour.ago }
      before {
        allow(subject.class).to receive(:id_from_external_entity_hash).and_return(id)
        allow(subject.class).to receive(:last_update_date_from_external_entity_hash).and_return(date)
        allow(subject.class).to receive(:creation_date_from_external_entity_hash).and_return(date)
      }
      
      describe 'consolidate_and_map_data' do
        context 'singleton' do
          before {
            allow(subject.class).to receive(:singleton?).and_return(true)
          }
          
          it 'returns the consolidate_and_map_singleton method result' do
            expect(subject).to receive(:consolidate_and_map_singleton).with({}, {}).and_return({result: 1})
            expect(subject.consolidate_and_map_data({}, {})).to eql({result: 1})
          end
        end

        context 'not singleton' do
          it 'calls the consolidation on both connec and external and returns an hash with the results' do
            expect(subject).to receive(:consolidate_and_map_connec_entities).with({}, {}, [], external_name).and_return({connec_result: 1})
            expect(subject).to receive(:consolidate_and_map_external_entities).with({}, connec_name).and_return({ext_result: 1})
            expect(subject.consolidate_and_map_data({}, {})).to eql({connec_entities: {connec_result: 1}, external_entities: {ext_result: 1}})
          end
        end
      end

      describe 'consolidate_and_map_singleton' do
        let(:connec_id) { [{'id' => 'lala', 'provider' => 'connec', 'realm' => 'realm'}] }
        before {
          allow(subject).to receive(:map_to_connec).and_return({map: 'connec'})
          allow(subject).to receive(:map_to_external).and_return({map: 'external'})
          allow(subject.class).to receive(:object_name_from_connec_entity_hash).and_return('connec human name')
          allow(subject.class).to receive(:object_name_from_external_entity_hash).and_return('external human name')
        }

        it { expect(subject.consolidate_and_map_singleton([], [])).to eql({connec_entities: [], external_entities: []}) }

        context 'with no idmap' do
          it 'creates one for connec' do
            expect{
              subject.consolidate_and_map_singleton([{'id' => connec_id}], [])
            }.to change{ Maestrano::Connector::Rails::IdMap.count }.by(1)
            idmap = Maestrano::Connector::Rails::IdMap.last
            expect(idmap.connec_entity).to eql(connec_name.downcase)
            expect(idmap.external_entity).to eql(external_name.downcase)
            expect(idmap.name).to eql('connec human name')
          end

          it 'creates one for external' do
            expect{
              subject.consolidate_and_map_singleton([], [{}])
            }.to change{ Maestrano::Connector::Rails::IdMap.count }.by(1)
            idmap = Maestrano::Connector::Rails::IdMap.last
            expect(idmap.connec_entity).to eql(connec_name.downcase)
            expect(idmap.external_entity).to eql(external_name.downcase)
            expect(idmap.external_id).to eql(id)
            expect(idmap.name).to eql('external human name')
          end
        end

        context 'with an idmap' do
          let!(:idmap) { create(:idmap, connec_entity: connec_name.downcase, external_entity: external_name.downcase, organization: organization) }

          it { expect{ subject.consolidate_and_map_singleton([{'id' => connec_id}], []) }.to_not change{ Maestrano::Connector::Rails::IdMap.count } }
        end

        context 'with conflict' do
          let!(:idmap) { create(:idmap, connec_entity: connec_name.downcase, external_entity: external_name.downcase, organization: organization, external_id: id) }
          let(:updated) { 3.hour.ago }
          let(:connec_entity) { {'id' => connec_id, 'updated_at' => updated} }

          context 'with options' do
            it 'keep the external one if connec_preemption is false' do
              subject.instance_variable_set(:@opts, {connec_preemption: false})
              expect(subject.consolidate_and_map_singleton([connec_entity], [{}])).to eql({connec_entities: [], external_entities: [{entity: {map: 'connec'}, idmap: idmap}]})
            end

            context 'when connec preemption is true' do
              let(:opts) { {connec_preemption: true} }

              it 'keep the connec one' do
                expect(subject.consolidate_and_map_singleton([connec_entity], [{}])).to eql({connec_entities: [{entity: {map: 'external'}, idmap: idmap, id_refs_only_connec_entity: {}}], external_entities: []})
              end

              it 'map with the unfolded references' do
                expect(subject).to receive(:map_to_external).with('id' => nil, 'updated_at' => updated)
                subject.consolidate_and_map_singleton([connec_entity], [{}])
              end
            end
          end

          context 'without options' do
            context 'with a more recent external one' do
              it { expect(subject.consolidate_and_map_singleton([connec_entity], [{}])).to eql({connec_entities: [], external_entities: [{entity: {map: 'connec'}, idmap: idmap}]}) }
            end
            context 'with a more recent connec one' do
              let(:updated) { 2.minute.ago }
              it { expect(subject.consolidate_and_map_singleton([connec_entity], [{}])).to eql({connec_entities: [{entity: {map: 'external'}, idmap: idmap, id_refs_only_connec_entity: {}}], external_entities: []}) }
            end
          end
        end
      end

      describe 'consolidate_and_map_connec_entities' do
        let(:connec_human_name) { 'connec human name' }
        let(:id1) { 'external-unfolded-id' }
        let(:id2) { nil }
        let(:connec_id1) { 'connec-id-1' }
        let(:connec_id2) { 'connec-id-2' }
        let(:entity1) { {'id' => id1, 'name' => 'John', 'updated_at' => date, 'created_at' => date} }
        let(:entity2) { {'id' => id2, 'name' => 'Jane', 'updated_at' => date, 'created_at' => date} }
        let(:entity_without_refs) { {} }
        let(:entities) { [entity1, entity2] }
        let(:id_refs_only_connec_entity) { {a:1} }
        before {
          allow(subject.class).to receive(:object_name_from_connec_entity_hash).and_return(connec_human_name)
          allow(subject).to receive(:map_to_external).and_return({mapped: 'entity'})
          allow(Maestrano::Connector::Rails::ConnecHelper).to receive(:unfold_references).and_return({entity: entity1, connec_id: connec_id1, id_refs_only_connec_entity: id_refs_only_connec_entity}, {entity: entity2, connec_id: connec_id2, id_refs_only_connec_entity: id_refs_only_connec_entity}, {entity: nil})
        }

        context 'when idmaps do not exist' do
          it 'creates the idmaps with a name and returns the mapped entities with their idmaps' do
            expect{
              expect(subject.consolidate_and_map_connec_entities(entities, [], [], external_name)).to eql([{entity: {mapped: 'entity'}, idmap: Maestrano::Connector::Rails::IdMap.first, id_refs_only_connec_entity: id_refs_only_connec_entity}, {entity: {mapped: 'entity'}, idmap: Maestrano::Connector::Rails::IdMap.last, id_refs_only_connec_entity: id_refs_only_connec_entity}])
            }.to change{ Maestrano::Connector::Rails::IdMap.count }.by(2)
            expect(Maestrano::Connector::Rails::IdMap.last.name).to eql(connec_human_name)
          end
        end

        context 'when idmap exists' do
          let(:entities) { [entity1] }
          let!(:idmap1) { create(:idmap, organization: organization, connec_entity: connec_name.downcase, external_entity: external_name.downcase, external_id: id1, connec_id: connec_id1) }

          it 'does not create an idmap' do
            expect{
              subject.consolidate_and_map_connec_entities(entities, [], [], external_name)
            }.to_not change{ Maestrano::Connector::Rails::IdMap.count }
          end

          it 'returns the entity with its idmap' do
            expect(subject.consolidate_and_map_connec_entities(entities, [], [], external_name)).to eql([{entity: {mapped: 'entity'}, idmap: idmap1, id_refs_only_connec_entity: id_refs_only_connec_entity}])
          end

          context 'when external inactive' do
            before { idmap1.update(external_inactive: true) }
            it 'discards the entity' do
              expect(subject.consolidate_and_map_connec_entities(entities, [], [], external_name)).to eql([])
            end
          end

          context 'when to external flag is false' do
            before { idmap1.update(to_external: false) }
            it 'discards the entity' do
              expect(subject.consolidate_and_map_connec_entities(entities, [], [], external_name)).to eql([])
            end
          end

          context 'when last_push_to_external is recent' do
            before { idmap1.update(last_push_to_external: 2.second.ago) }
            it 'discards the entity' do
              expect(subject.consolidate_and_map_connec_entities(entities, [], [], external_name)).to eql([])
            end

            context 'with full synchronization opts' do
              let(:opts) { {full_sync: true} }

              it 'keeps the entity' do
                expect(subject.consolidate_and_map_connec_entities(entities, [], [], external_name)).to eql([{entity: {mapped: 'entity'}, idmap: idmap1, id_refs_only_connec_entity: id_refs_only_connec_entity}])
              end
            end
          end

          context 'when before date_filtering_limit' do
            before {
              organization.update(date_filtering_limit: 5.minutes.ago)
            }

            it 'discards the entity' do
              expect(subject.consolidate_and_map_connec_entities(entities, [], [], external_name)).to eql([])
            end

            context 'with full synchronization opts' do
              let(:opts) { {full_sync: true} }

              it 'keeps the entity' do
                expect(subject.consolidate_and_map_connec_entities(entities, [], [], external_name)).to eql([{entity: {mapped: 'entity'}, idmap: idmap1, id_refs_only_connec_entity: id_refs_only_connec_entity}])
              end
            end
          end

        end

        context 'when conflict' do
          let(:entities) { [entity1] }
          let(:external_entity_1) { {'id' => id1} }
          let(:external_entities) { [external_entity_1] }
          before {
            allow(subject.class).to receive(:id_from_external_entity_hash).and_return(id1)
          }

          context 'with opts' do
            context 'with connec preemption false' do
              it 'discards the entity and keep the external one' do
                subject.instance_variable_set(:@opts, {connec_preemption: false})
                expect(subject.consolidate_and_map_connec_entities(entities, external_entities, [], external_name)).to eql([])
                expect(external_entities).to_not be_empty
              end
            end

            context 'with connec preemption true' do
              it 'keeps the entity and discards the external one' do
                subject.instance_variable_set(:@opts, {connec_preemption: true})
                expect(subject.consolidate_and_map_connec_entities(entities, external_entities, [], external_name)).to eql([{entity: {mapped: 'entity'}, idmap: Maestrano::Connector::Rails::IdMap.first, id_refs_only_connec_entity: id_refs_only_connec_entity}])
                expect(external_entities).to be_empty
              end
            end
          end

          context 'without opts' do
            before {
              allow(subject.class).to receive(:last_update_date_from_external_entity_hash).and_return(external_date)
            }

            context 'with connec one more recent' do
              let(:external_date) { 1.year.ago } 
              let(:date) { 1.day.ago } 

              it 'keeps the entity and discards the external one' do
                expect(subject.consolidate_and_map_connec_entities(entities, external_entities, [], external_name)).to eql([{entity: {mapped: 'entity'}, idmap: Maestrano::Connector::Rails::IdMap.first, id_refs_only_connec_entity: id_refs_only_connec_entity}])
                expect(external_entities).to be_empty
              end
            end

            context 'with external one more recent' do
              let(:external_date) { 1.month.ago } 
              let(:date) { 1.year.ago } 

              it 'discards the entity and keep the external one' do
                expect(subject.consolidate_and_map_connec_entities(entities, external_entities, [], external_name)).to eql([])
                expect(external_entities).to_not be_empty
              end
            end
          end
        end
      end

      describe 'consolidate_and_map_external_entities' do
        let(:entity) { {'id' => id, 'name' => 'Jane'} }
        let(:id) { 'id' }
        let(:external_human_name) { 'external human name' }
        before {
          allow(subject.class).to receive(:id_from_external_entity_hash).and_return(id)
          allow(subject.class).to receive(:object_name_from_external_entity_hash).and_return(external_human_name)
          allow(subject).to receive(:map_to_connec).and_return({mapped: 'ext_entity'})
        }

        context 'when idmap exists' do
          let!(:idmap) { create(:idmap, organization: organization, connec_entity: connec_name.downcase, external_entity: external_name.downcase, external_id: id) }

          it 'does not create one' do
            expect{
              subject.consolidate_and_map_external_entities([entity], connec_name)
            }.to_not change{ Maestrano::Connector::Rails::IdMap.count }
          end

          it 'returns the mapped entity with the idmap' do
            expect(subject.consolidate_and_map_external_entities([entity], connec_name)).to eql([{entity: {mapped: 'ext_entity'}, idmap: idmap}])
          end

          context 'when to_connec is false' do
            before { idmap.update(to_connec: false) }

            it 'discards the entity' do
              expect(subject.consolidate_and_map_external_entities([entity], connec_name)).to eql([])
            end
          end

          context 'when entity is inactive' do
            before {
              allow(subject.class).to receive(:inactive_from_external_entity_hash?).and_return(true)
            }

            it 'discards the entity' do
              expect(subject.consolidate_and_map_external_entities([entity], connec_name)).to eql([])
            end

            it 'updates the idmaps' do
              subject.consolidate_and_map_external_entities([entity], connec_name)
              expect(idmap.reload.external_inactive).to be true
            end
          end

          context 'when last_push_to_connec is recent' do
            before { idmap.update(last_push_to_connec: 2.second.ago) }

            it 'discards the entity' do
              expect(subject.consolidate_and_map_external_entities([entity], connec_name)).to eql([])
            end

            context 'with full synchronization opts' do
              let(:opts) { {full_sync: true} }

              it 'keeps the entity' do
                expect(subject.consolidate_and_map_external_entities([entity], connec_name)).to eql([{entity: {mapped: 'ext_entity'}, idmap: idmap}])
              end
            end
          end

          context 'when before date_filtering_limit' do
            before {
              organization.update(date_filtering_limit: 5.minutes.ago)
            }

            it 'discards the entity' do
              expect(subject.consolidate_and_map_external_entities([entity], connec_name)).to eql([])
            end

            context 'with full synchronization opts' do
              let(:opts) { {full_sync: true} }

              it 'keeps the entity' do
                expect(subject.consolidate_and_map_external_entities([entity], connec_name)).to eql([{entity: {mapped: 'ext_entity'}, idmap: idmap}])
              end
            end
          end

        end
      end
    end


  end
end