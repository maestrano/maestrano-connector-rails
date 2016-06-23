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
        __connec_id: 'abcd',
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
      }
    }
    let(:lt1_id_id) { 'lt1_id' }
    let(:lt2_id_id) { 'lt2_id' }
    let(:lt1_id) { [subject.id_hash(lt1_id_id, organization)] }
    let(:lt2_id) { [subject.id_hash(lt2_id_id, organization)] }

    context 'when all ids are here' do
      let(:id_id) { 'id' }
      let(:org_id_id) { 'org_id' }
      let(:id) { [subject.id_hash(id_id, organization), {'provider' => 'connec', 'id' => 'abcd'}] }
      let(:org_id) { [subject.id_hash(org_id_id, organization), {'provider' => 'connec', 'id' => 'abcd'}] }

      it 'unfolds everything' do
        expect(subject.unfold_references(connec_hash, ['organization_id', 'lines/linked_transaction/id'], organization)).to eql(output_hash.with_indifferent_access)
      end
    end

    context 'when only id is missing' do
      let(:id_id) { nil }
      let(:org_id_id) { 'org_id' }
      let(:id) { [{'provider' => 'connec', 'realm' => 'some realm', 'id' => 'id'}] }
      let(:org_id) { [subject.id_hash(org_id_id, organization)] }

      it 'unfolds the other refs and keep the connec_id' do
        expect(subject.unfold_references(connec_hash, ['organization_id', 'lines/linked_transaction/id'], organization)).to eql(output_hash.merge(__connec_id: 'id').with_indifferent_access)
      end
    end

    context 'when at least one ref is missing and there is a connec id' do
      let(:id_id) { nil }
      let(:org_id_id) { 'org_id' }
      let(:id) { [{'provider' => 'connec', 'realm' => 'some realm', 'id' => 'id'}] }
      let(:org_id) { [{'provider' => 'connec', 'realm' => 'some realm', 'id' => org_id_id}] }

      it 'returns nil' do
        expect(subject.unfold_references(connec_hash, ['organization_id', 'lines/linked_transaction/id'], organization)).to be_nil
      end
    end
    context 'when at least one ref is missing but there is no connec id' do
      let(:id_id) { 'id' }
      let(:id) { [subject.id_hash(id_id, organization), {'provider' => 'connec', 'id' => 'abcd'}] }
      let(:org_id_id) { nil }
      let(:org_id) { nil }

      it 'unfold the others refs' do
        expect(subject.unfold_references(connec_hash, ['organization_id', 'lines/linked_transaction/id'], organization)).to eql(output_hash.merge(organization_id: nil).with_indifferent_access)
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

    context 'when id is an integer' do
      let(:id) { 1234 }

      it 'folds the existing refs' do
        expect(subject.fold_references(mapped_hash, ['organization_id', 'contact/id', 'lines/id', 'not_here_ref'], organization)).to eql(output_hash.with_indifferent_access)
      end
    end
  end
end
