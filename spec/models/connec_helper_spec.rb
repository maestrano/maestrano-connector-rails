require 'spec_helper'

describe Maestrano::Connector::Rails::ConnecHelper do
  subject { Maestrano::Connector::Rails::ConnecHelper }

  let!(:organization) { create(:organization) }

  describe 'dependancies' do
    it 'returns a default hash' do
      expect(subject.dependancies).to eql({
        connec: '1.0',
        impac: '1.0',
        maestrano_hub: '1.0'
      })
    end
  end

  describe 'connec_version' do
    let!(:organization) { create(:organization, tenant: 'default') }
    let!(:organization2) { create(:organization, tenant: 'default2') }
    before {
      allow(Maestrano::Connec::Client).to receive(:get).and_return(ActionDispatch::Response.new(200, {}, {ci_build_number: '111', ci_branch: 'v1.1', ci_commit: '111'}.to_json, {}), ActionDispatch::Response.new(200, {}, {ci_build_number: '112', ci_branch: 'v1.2', ci_commit: '112'}.to_json, {}))
    }

    it 'returns the connec_version' do
      expect(Maestrano::Connec::Client).to receive(:get).twice
      expect(subject.connec_version(organization)).to eql('1.1')
      expect(subject.connec_version(organization2)).to eql('1.2')
      expect(subject.connec_version(organization)).to eql('1.1')
      expect(subject.connec_version(organization2)).to eql('1.2')
    end

  end

  describe 'unfold_references' do
    let(:connec_hash) {
      {
        id: id,
        organization_id: org_id,
        lines: [
          {
            linked_transaction: {
              id: lt1_id
            }
          },
          {
            linked_transaction: {
              id: lt2_id
            }
          }
        ]
      }
    }

    let(:output_hash) {
      {
        connec_id: connec_id,
        entity: {
          id: id_id,
          organization_id: org_id_id,
          lines: [
            {
              linked_transaction: {
                id: lt1_id_id
              }
            },
            {
              linked_transaction: {
                id: lt2_id_id
              }
            }
          ]
        }.with_indifferent_access,
        id_refs_only_connec_entity: {}
      }
    }
    let(:lt1_id_id) { 'lt1_id' }
    let(:lt2_id_id) { 'lt2_id' }
    let(:lt1_id) { [subject.id_hash(lt1_id_id, organization)] }
    let(:lt2_id) { [subject.id_hash(lt2_id_id, organization)] }
    let(:connec_id) { 'cid1' }
    let(:connec_org_id) { 'cid2' }
    let(:org_id_id) { 'org_id' }

    context 'when all ids are here' do
      let(:id_id) { 'id' }
      let(:id) { [subject.id_hash(id_id, organization), {'provider' => 'connec', 'id' => connec_id}] }
      let(:org_id) { [subject.id_hash(org_id_id, organization), {'provider' => 'connec', 'id' => connec_org_id}] }

      it 'unfolds everything' do
        expect(subject.unfold_references(connec_hash, ['organization_id', 'lines/linked_transaction/id'], organization)).to eql(output_hash)
      end
    end

    context 'when only id is missing' do
      let(:id_id) { nil }
      let(:id) { [{'provider' => 'connec', 'realm' => 'some realm', 'id' => connec_id}] }
      let(:org_id) { [subject.id_hash(org_id_id, organization)] }

      it 'unfolds the other refs and keep the connec_id' do
        expect(subject.unfold_references(connec_hash, ['organization_id', 'lines/linked_transaction/id'], organization)).to eql(output_hash.merge(connec_id: connec_id))
      end
    end

    context 'when at least one ref is missing and there is a connec id' do
      let(:id_id) { nil }
      let(:id) { [{'provider' => 'connec', 'realm' => 'some realm', 'id' => connec_id}] }
      let(:org_id) { [{'provider' => 'connec', 'realm' => 'some realm', 'id' => connec_org_id}] }

      it 'returns nil' do
        expect(subject.unfold_references(connec_hash, ['organization_id', 'lines/linked_transaction/id'], organization)).to eql(output_hash.merge(entity: nil))
      end
    end
    context 'when at least one ref is missing but there is no connec id' do
      let(:id_id) { 'id' }
      let(:id) { [subject.id_hash(id_id, organization), {'provider' => 'connec', 'id' => connec_id}] }
      let(:org_id_id) { nil }
      let(:org_id) { nil }

      it 'unfold the others refs' do
        expect(subject.unfold_references(connec_hash, ['organization_id', 'lines/linked_transaction/id'], organization)).to eql(output_hash)
      end
    end

    describe 'when reference field is a string instead of an array' do
      let(:connec_hash) {
        {
          id: [subject.id_hash('123', organization), {'provider' => 'connec', 'id' => 'abcd'}],
          organization_id: 'an unexpected string id',
        }
      }

      let(:output_hash) {
        {
          connec_id: 'abcd',
          entity: {
            id: '123'
          }.with_indifferent_access,
          id_refs_only_connec_entity: {}
        }
      }

      it 'ignores the string' do
        expect(subject.unfold_references(connec_hash, ['organization_id'], organization)).to eql(output_hash)
      end
    end
  end

  describe 'fold_references' do
    let(:id) { 'id1' }
    let(:mapped_hash) {
      {
        id: id,
        organization_id: nil,
        contact: {
          id: ''
        },
        lines: [
          {
            id: 'id2'
          },
          {
            id: 'id3'
          }
        ]
      }
    }

    let(:output_hash) {
      {
        "id" => [
          subject.id_hash(id, organization)
        ],
        "organization_id" => nil,
        "contact" => {
          "id" => ""
        },
        "lines" => [
          {
            "id" => [
              subject.id_hash('id2', organization)
            ]
          },
          {
            "id" => [
              subject.id_hash('id3', organization)
            ]
          }
        ]
      }
    }

    it 'folds the existing refs' do
      expect(subject.fold_references(mapped_hash, ['organization_id', 'contact/id', 'lines/id', 'not_here_ref'], organization)).to eql(output_hash.with_indifferent_access)
    end

    it 'folds the existing refs (both id and record refs)' do
      expect(subject.fold_references(mapped_hash, {record_references: %w(organization_id contact/id), id_references: %w(lines/id not_here_ref)}, organization)).to eql(output_hash.with_indifferent_access)
    end

    context 'when id is an integer' do
      let(:id) { 1234 }

      it 'folds the existing refs' do
        expect(subject.fold_references(mapped_hash, ['organization_id', 'contact/id', 'lines/id', 'not_here_ref'], organization)).to eql(output_hash.with_indifferent_access)
      end
    end
  end

  describe 'build_id_references_tree' do
    let(:id_references) { %w(lines/id lines/linked/id lines/linked/id2 linked/id) }
    let(:tree) {
      {
        "lines"=>{
          "id"=>{},
          "linked"=>{
            "id"=>{},
            "id2"=>{}
          }
        },
        "linked"=>{
          "id"=>{}
        }
      }
    }

    it 'returns the tree' do
      expect(subject.build_id_references_tree(id_references)).to eql(tree)
    end
  end

  describe 'format_references' do
    context 'when array' do
      it 'transforms it to an hash' do
        expect(subject.format_references([1])).to eql({record_references: [1], id_references: []})
      end
    end

    context 'when hash with both keys' do
      let(:hash) { {id_references: [1], record_references: [2]} }
      it 'returns it' do
        expect(subject.format_references(hash)).to eql(hash)
      end
    end

    context 'when hash with only one key' do
      context 'when missing id_references' do
        it 'returns the completed hash' do
          expect(subject.format_references(record_references: [1])).to eql({record_references: [1], id_references: []})
        end
      end

      context 'when missing record_references' do
        it 'returns the completed hash' do
          expect(subject.format_references(id_references: [1])).to eql({id_references: [1], record_references: []})
        end
      end
    end
  end

  describe 'filter_connec_entity_for_id_refs' do
    let(:connec_entity) {
      {
        id: [{"id"=>"001", "provider"=>"this_app", "realm"=>"sfuiy765"}],
        name: "Brewer Supplies Ltd",
        description: "We supply all things brewed\n",
        lines: [
          {
            id: [{"id"=>"002", "provider"=>"this_app", "realm"=>"sfuiy765"}],
            amount: 12,
            linked: {
              linked_transactions: [
                {
                  class: 'Invoice',
                  id: [{"id"=>"003", "provider"=>"this_app", "realm"=>"sfuiy765"}],
                  id2: [{"id"=>"013", "provider"=>"this_app", "realm"=>"sfuiy765"}],
                },
                {
                  class: 'Sales order',
                  id: [{"id"=>"004", "provider"=>"this_app", "realm"=>"sfuiy765"}],
                  id2: [{"id"=>"014", "provider"=>"this_app", "realm"=>"sfuiy765"}],
                }
              ]
            }
          }
        ],
        linked_transactions: [
          {
            class: 'Test',
            id: [{"id"=>"005", "provider"=>"this_app", "realm"=>"sfuiy765"}],
          }
        ]
      }
    }

    context 'with id_references' do
      let(:id_references) { %w(lines/id lines/linked/linked_transactions/id lines/linked/linked_transactions/id2 linked_transactions/id) }
      let(:filtered_connec_entity) {
        {
          lines: [
            {
              id: [{"id"=>"002", "provider"=>"this_app", "realm"=>"sfuiy765"}],
              linked: {
                linked_transactions: [
                  {
                    id: [{"id"=>"003", "provider"=>"this_app", "realm"=>"sfuiy765"}],
                    id2: [{"id"=>"013", "provider"=>"this_app", "realm"=>"sfuiy765"}],
                  },
                  {
                    id: [{"id"=>"004", "provider"=>"this_app", "realm"=>"sfuiy765"}],
                    id2: [{"id"=>"014", "provider"=>"this_app", "realm"=>"sfuiy765"}],
                  }
                ]
              }
            }
          ],
          linked_transactions: [
            {
              id: [{"id"=>"005", "provider"=>"this_app", "realm"=>"sfuiy765"}],
            }
          ]
        }.with_indifferent_access
      }

      it 'returns the connec_entity with only the relevant keys' do
        expect(subject.filter_connec_entity_for_id_refs(connec_entity, id_references)).to eql(filtered_connec_entity)
      end
    end

    context 'without id_references' do
      it 'returns an empty hash' do
        expect(subject.filter_connec_entity_for_id_refs(connec_entity, [])).to eql({})
      end
    end
  end

  describe 'value from hash' do
    let(:hash) {
      {
        lines: [
          {
            linked: [
              {
                a: {
                  b: [1]
                }
              }
            ]
          },
          {
            linked: [
              {
                a: {
                  b: [2]
                }
              },
              {
                a: {
                  b: [3]
                }
              }
            ]
          },
        ]
      }
    }

    let(:path) { [:lines, 1,:linked, 0, :a, :b] }

    it 'returns the value from the path' do
      expect(subject.value_from_hash(hash, path)).to eql([2])
    end

    context 'when the path leads to nowhere' do
      context 'with a wrong array' do
        let(:hash) {
          {
            lines: [
              {
                linked: [
                  {
                    a: {
                      b: [1]
                    }
                  }
                ]
              },
            ]
          }
        }

        it 'returns nil' do
          expect(subject.value_from_hash(hash, path)).to eql(nil)
        end
      end

      context 'with a wrong hash' do
        let(:hash) {
          {
            lines: [
              {
              },
              {
                linked: [
                  {
                  },
                  {
                  }
                ]
              },
            ]
          }
        }

        it 'returns nil' do
          expect(subject.value_from_hash(hash, path)).to eql(nil)
        end
      end
    end
  end

  describe 'merge_id_hashes' do
    let(:dist) {
      {
        lines: [
          {
            id: [{"id"=>"002", "provider"=>"connec", "realm"=>"org-123"}],
            linked: {
              linked_transactions: [
                {
                  id: [{"id"=>"003", "provider"=>"connec", "realm"=>"org-123"}],
                  id2: [{"id"=>"013", "provider"=>"connec", "realm"=>"org-123"}],
                },
                {
                  id: [{"id"=>"004", "provider"=>"connec", "realm"=>"org-123"}],
                  id2: [{"id"=>"014", "provider"=>"connec", "realm"=>"org-123"}],
                }
              ]
            }
          }
        ],
        linked_transactions: [
          {
            id: [{"id"=>"005", "provider"=>"connec", "realm"=>"org-123"}],
          }
        ]
      }
    }

    let(:src) {
      {
        title: 'Title',
        lines: [
          {
            amount: 123,
            id: [{"id"=>"002", "provider"=>"this-app", "realm"=>"6543"}],
            linked: {
              linked_transactions: [
                {
                  class: 'Invoice',
                  id: [{"id"=>"003", "provider"=>"this-app", "realm"=>"6543"}],
                  id2: [{"id"=>"013", "provider"=>"this-app", "realm"=>"6543"}],
                },
                {
                  class: 'Sales Order',
                  id: [{"id"=>"004", "provider"=>"this-app", "realm"=>"6543"}],
                  id2: [{"id"=>"014", "provider"=>"this-app", "realm"=>"6543"}],
                }
              ]
            }
          }
        ],
        linked_transactions: [
          {
            class: 'Payment',
            id: [{"id"=>"005", "provider"=>"this-app", "realm"=>"6543"}],
          }
        ]
      }
    }

    let(:id_references) {
      %w(lines/id lines/linked/linked_transactions/id lines/linked/linked_transactions/id2 linked_transactions/id)
    }

    let(:output_hash) {
      {
        lines: [
          {
            id: [{"id"=>"002", "provider"=>"connec", "realm"=>"org-123"}, {"id"=>"002", "provider"=>"this-app", "realm"=>"6543"}],
            linked: {
              linked_transactions: [
                {
                  id: [{"id"=>"003", "provider"=>"connec", "realm"=>"org-123"}, {"id"=>"003", "provider"=>"this-app", "realm"=>"6543"}],
                  id2: [{"id"=>"013", "provider"=>"connec", "realm"=>"org-123"}, {"id"=>"013", "provider"=>"this-app", "realm"=>"6543"}],
                },
                {
                  id: [{"id"=>"004", "provider"=>"connec", "realm"=>"org-123"}, {"id"=>"004", "provider"=>"this-app", "realm"=>"6543"}],
                  id2: [{"id"=>"014", "provider"=>"connec", "realm"=>"org-123"}, {"id"=>"014", "provider"=>"this-app", "realm"=>"6543"}],
                }
              ]
            }
          }
        ],
        linked_transactions: [
          {
            id: [{"id"=>"005", "provider"=>"connec", "realm"=>"org-123"}, {"id"=>"005", "provider"=>"this-app", "realm"=>"6543"}],
          }
        ]
      }.with_indifferent_access
    }

    it 'merge the id from the src to the dist' do
      expect(subject.merge_id_hashes(dist, src, id_references)).to eql(output_hash)
    end

    describe 'edge cases' do
      context 'uncomplete src' do
        describe 'when an id is missing in an array' do
          before {
            src[:linked_transactions] = []
            output_hash[:linked_transactions].first.delete(:id)
          }

          it 'does not merge this id' do
            expect(subject.merge_id_hashes(dist, src, id_references)).to eql(output_hash)
          end
        end

        describe 'when an id is missing in a hash' do
          before {
            src[:lines].first.delete(:id)
            output_hash[:lines].first.delete(:id)
          }

          it 'does not merge this id' do
            expect(subject.merge_id_hashes(dist, src, id_references)).to eql(output_hash)
          end
        end
      end

      context 'uncomplete dist' do
        describe 'when an id is missing in an array' do
          before {
            dist[:linked_transactions] = []
            output_hash[:linked_transactions] = []
          }

          it 'does not merge this id' do
            expect(subject.merge_id_hashes(dist, src, id_references)).to eql(output_hash)
          end
        end

        describe 'when an id is missing in a hash' do
          before {
            dist[:lines].first.delete(:id)
            output_hash[:lines].first.delete(:id)
          }

          it 'does not merge this id' do
            expect(subject.merge_id_hashes(dist, src, id_references)).to eql(output_hash)
          end
        end
      end
    end
  end
end
