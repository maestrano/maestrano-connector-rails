require 'spec_helper'

describe 'connec to the external application' do

  class Entities::ConnecToExternal < Maestrano::Connector::Rails::Entity
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

    def self.object_name_from_connec_entity_hash(entity)
      entity['first_name']
    end

    def self.id_from_external_entity_hash(entity)
      entity['ID']
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
  let(:person1) {
    {
      "id" => [
        {
          "realm" => "org-fg4a",
          "provider" => "connec",
          "id" => "23daf041-e18e-0133-7b6a-15461b913fab"
        }
      ],
      "code" => "PE3",
      "status" => "ACTIVE",
      "first_name" => "John",
      "last_name" => "Doe",
      "organization_id" => [
        {
          "realm" => "org-fg4a",
          "provider" => "connec",
          "id" => "2305c5e0-e18e-0133-890f-07d4de9f9781"
        },
        {
          "realm" => oauth_uid,
          "provider" => provider,
          "id" => ext_org_id
        }
      ],
      "is_customer" => false,
      "is_supplier" => true,
      "is_lead" => false,
      "updated_at" => 2.day.ago,
      "created_at" => 2.day.ago
    }
  }
  let(:person) { person1 }


  before {
    allow(connec_client).to receive(:get).and_return(ActionDispatch::Response.new(200, {}, {people: [person]}.to_json, {}))
    allow(connec_client).to receive(:batch).and_return(ActionDispatch::Response.new(200, {}, {results: [{status: 200, body: {people: {}}}]}.to_json, {}))

    allow_any_instance_of(Entities::ConnecToExternal).to receive(:get_external_entities).and_return([])
  }

  subject { Maestrano::Connector::Rails::SynchronizationJob.new.sync_entity('connec_to_external', organization, connec_client, external_client, organization.last_synchronization_date, {}) }

  describe 'a new record created in connec with all references known' do
    before {
      allow_any_instance_of(Entities::ConnecToExternal).to receive(:create_external_entity).and_return({'ID' => ext_contact_id})
    }

    let(:mapped_entity) {
      {
        AccountId: ext_org_id,
        FirstName: 'John'
      }
    }

    let(:batch_params) {
      {
        :sequential=>true,
        :ops=> [
          {
            :method=>"put", 
            :url=>"/api/v2/#{organization.uid}/people/23daf041-e18e-0133-7b6a-15461b913fab", 
            :params=>
            {
              :people=>{
                id: [
                  {
                    :id=>"ext contact id",
                    :provider=>"provider",
                    :realm=>"oauth uid"
                  }
                ]
              }
            }
          }
        ]
      }
    }

    it 'handles the idmap correctly' do
      expect{
        subject
      }.to change{ Maestrano::Connector::Rails::IdMap.count }.by(1)
      idmap = Maestrano::Connector::Rails::IdMap.last
      expect(idmap.name).to eql('John')
      expect(idmap.connec_entity).to eql('person')
      expect(idmap.external_entity).to eql('contact')
      expect(idmap.message).to be_nil
      expect(idmap.external_id).to eql(ext_contact_id)
      expect(idmap.connec_id).to eql("23daf041-e18e-0133-7b6a-15461b913fab")
    end

    it 'does the mapping correctly' do
      idmap = Entities::ConnecToExternal.create_idmap(organization_id: organization.id, external_id: ext_contact_id, connec_id: "23daf041-e18e-0133-7b6a-15461b913fab")
      allow(Entities::ConnecToExternal).to receive(:find_or_create_idmap).and_return(idmap)
      expect_any_instance_of(Entities::ConnecToExternal).to receive(:push_entities_to_external).with([{entity: mapped_entity.with_indifferent_access, idmap: idmap, id_refs_only_connec_entity: {}}])
      subject
    end

    it 'send the external id to connec' do
      expect(connec_client).to receive(:batch).with(batch_params)
      subject
    end
  end

  describe 'an update from connec with all references known' do
    before {
      allow_any_instance_of(Entities::ConnecToExternal).to receive(:update_external_entity).and_return(nil)
    }
    let(:person) { person1.merge('first_name' => 'Jane', 'id' => person1['id'] << {'id' => ext_contact_id, 'provider' => provider, 'realm' => oauth_uid}) }
    let!(:idmap) { Entities::ConnecToExternal.create_idmap(organization_id: organization.id, external_id: ext_contact_id, connec_id: "23daf041-e18e-0133-7b6a-15461b913fab") }

    let(:mapped_entity) {
      {
        AccountId: ext_org_id,
        FirstName: 'Jane'
      }
    }

    it 'update the idmap' do
      subject
      expect(idmap.reload.message).to be_nil
      expect(idmap.reload.name).to eql('Jane')
      expect(idmap.reload.last_push_to_external > 1.minute.ago).to be true
    end

    it 'does the mapping correctly' do
      expect_any_instance_of(Entities::ConnecToExternal).to receive(:push_entities_to_external).with([{entity: mapped_entity.with_indifferent_access, idmap: idmap, id_refs_only_connec_entity: {}}])
      subject
    end

    it 'does not send the external id to connec' do
      expect(connec_client).to_not receive(:batch)
      subject
    end

  end

  describe 'a creation from connec with references missing' do
    let(:person) { person1.merge("organization_id" => [{"realm"=>"org-fg4a", "provider"=>"connec", "id"=>"2305c5e0-e18e-0133-890f-07d4de9f9781"}]) }
    
    it 'pushes nothing and creates no idmap' do
      expect_any_instance_of(Entities::ConnecToExternal).to_not receive(:create_external_entity)
      expect_any_instance_of(Entities::ConnecToExternal).to_not receive(:update_external_entity)
      expect{
        subject
      }.to_not change{ Maestrano::Connector::Rails::IdMap.count }
    end
  end

  describe 'an entity from before the date filtering limit' do
    let(:date_filtering_limit) { 2.minute.ago }
    before {
      organization.update(date_filtering_limit: date_filtering_limit)
    }

    it 'calls get_connec_entities with a date even if there is no last sync' do
      expect_any_instance_of(Entities::ConnecToExternal).to receive(:get_connec_entities).with(date_filtering_limit).and_return([])
      subject
    end

    it 'pushes nothing and creates no idmap' do
      expect_any_instance_of(Entities::ConnecToExternal).to_not receive(:create_external_entity)
      expect_any_instance_of(Entities::ConnecToExternal).to_not receive(:update_external_entity)
      expect{
        subject
      }.to_not change{ Maestrano::Connector::Rails::IdMap.count }
    end
  end
end
