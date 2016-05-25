require 'spec_helper'

describe 'external application to connec' do

  class Entities::ExternalToConnec < Maestrano::Connector::Rails::Entity
    def self.external_entity_name
      'Contact'
    end

    def self.connec_entity_name
      'Person'
    end

    def self.mapper_class
      PersonMapper
    end

    def self.references
      ['organization_id']
    end

    def self.object_name_from_external_entity_hash(entity)
      entity['FirstName']
    end

    def self.id_from_external_entity_hash(entity)
      entity['Id']
    end

    class PersonMapper
      extend HashMapper
      map from('organization_id'), to('AccountId')
      map from('first_name'), to('FirstName')
    end
  end

  let(:provider) { 'provider' }
  let(:oauth_uid) { 'oauth uid' }
  let!(:organization) { create(:organization, oauth_provider: provider, oauth_uid: oauth_uid) }
  let(:connec_client) { Maestrano::Connec::Client[organization.tenant].new(organization.uid) }
  let(:external_client) { Object.new }

  let(:ext_org_id) { 'ext org id' }
  let(:ext_contact_id) { 'ext contact id' }

  let(:contact1) {
    {
      'Id' => ext_contact_id,
      'FirstName' => 'Jack',
      'AccountId' => ext_org_id
    }
  }
  let(:contact) { contact1 }

  let(:mapped_entity1) {
    {
      id: [
        {
          provider: provider,
          realm: oauth_uid,
          id: ext_contact_id
        }
      ],
      first_name: 'Jack',
      organization_id: [
        {
          provider: provider,
          realm: oauth_uid,
          id: ext_org_id
        }
      ]
    }
  }
  let(:mapped_entity) { mapped_entity1 }

  let(:batch_call) {
    {
      :sequential => true,
      :ops => [
        {
          :method => "post",
          :url => "/api/v2/#{organization.uid}/people/",
          :params => {
            :people => mapped_entity
          }
        }
      ]
    }
  }

  before {
    allow_any_instance_of(Entities::ExternalToConnec).to receive(:get_connec_entities).and_return([])
    allow_any_instance_of(Entities::ExternalToConnec).to receive(:get_external_entities).and_return([contact])
  }

  subject { Maestrano::Connector::Rails::SynchronizationJob.new.sync_entity('external_to_connec', organization, connec_client, external_client, nil, {}) }

  describe 'creating an record in connec' do
    before {
      allow(connec_client).to receive(:batch).and_return(ActionDispatch::Response.new(201, {}, {results: [{status: 201, body: {people: {id: [{provider: 'connec', id: 'connec-id'}]}}}]}.to_json, {}))
    }

    it 'handles the idmap correctly' do
      expect{
        subject
      }.to change{ Maestrano::Connector::Rails::IdMap.count }.by(1)
      idmap = Maestrano::Connector::Rails::IdMap.last
      expect(idmap.name).to eql('Jack')
      expect(idmap.connec_entity).to eql('person')
      expect(idmap.external_entity).to eql('contact')
      expect(idmap.message).to be_nil
      expect(idmap.external_id).to eql(ext_contact_id)
    end

    it 'does the mapping correctly' do
      idmap = Entities::ExternalToConnec.create_idmap(organization_id: organization.id, external_id: ext_contact_id)
      allow(Entities::ExternalToConnec).to receive(:create_idmap).and_return(idmap)
      expect_any_instance_of(Entities::ExternalToConnec).to receive(:push_entities_to_connec).with([{entity: mapped_entity, idmap: idmap}])
      subject
    end

    it 'does the right call to connec' do
      expect(connec_client).to receive(:batch).with(batch_call)
      subject
      expect(Maestrano::Connector::Rails::IdMap.last.connec_id).to eql('connec-id')
    end
  end

  describe 'updating an record in connec' do
    before {
      allow(connec_client).to receive(:batch).and_return(ActionDispatch::Response.new(201, {}, {results: [{status: 201, body: {people: {id: [{provider: 'connec', id: 'connec-id'}]}}}]}.to_json, {}))
    }
    let(:contact) { contact1.merge('FirstName' => 'Jacky') }
    let(:mapped_entity) { mapped_entity1.merge(first_name: 'Jacky') }
    let!(:idmap) { Entities::ExternalToConnec.create_idmap(organization_id: organization.id, external_id: ext_contact_id, connec_id: 'connec-id') }

    it 'handles the idmap correctly' do
      expect{
        subject
      }.to_not change{ Maestrano::Connector::Rails::IdMap.count }
      expect(idmap.reload.name).to eql('Jacky')
      expect(idmap.reload.message).to be_nil
    end

    it 'does the mapping correctly' do
      expect_any_instance_of(Entities::ExternalToConnec).to receive(:push_entities_to_connec).with([{entity: mapped_entity, idmap: idmap}])
      subject
    end

    it 'does the right call to connec' do
      expect(connec_client).to receive(:batch).with(batch_call)
      subject
    end
  end
end
