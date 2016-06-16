require 'spec_helper'

describe 'singleton workflow' do

  class Entities::SingletonIntegration < Maestrano::Connector::Rails::Entity
    def self.external_entity_name
      'Company'
    end

    def self.connec_entity_name
      'Company'
    end

    def self.mapper_class
      CompanyMapper
    end

    def self.object_name_from_connec_entity_hash(entity)
      entity['name']
    end

    def self.object_name_from_external_entity_hash(entity)
      entity['name']
    end

    def self.id_from_external_entity_hash(entity)
      entity['id']
    end

    def self.last_update_date_from_external_entity_hash(entity)
      entity['updated_at']
    end

    def self.singleton?
      true
    end

    class CompanyMapper
      extend HashMapper
      map from('id'), to('id')
      map from('name'), to('name')
    end
  end

  let(:provider) { 'provider' }
  let(:oauth_uid) { 'oauth uid' }
  let!(:organization) { create(:organization, oauth_provider: provider, oauth_uid: oauth_uid) }
  let(:connec_client) { Maestrano::Connec::Client[organization.tenant].new(organization.uid) }
  let(:external_client) { Object.new }
  let(:ext_comp_id) { 'ext comp id' }
  let(:connec_updated) { 1.hour.ago }
  let(:ext_updated) { 1.hour.ago }
  let(:company_base) {
    {
      "name" => "My awesome company",
      "updated_at" => connec_updated.iso8601
    }
  }

  let(:ext_company_base) {
    {
      'id' => ext_comp_id,
      'name' => 'My not so awesome store',
      'updated_at' => ext_updated.iso8601
    }
  }

  let(:mapped_connec_entity) {
    {
      id: ext_comp_id,
      name: "My awesome company"
    }
  }

  let(:mapped_external_entity) {
    {
      id: [
        {
          :id=>ext_comp_id,
          :provider=>provider,
          :realm=>oauth_uid
        }
      ],
      name: 'My not so awesome store'
    }
  }


  before {
    allow(connec_client).to receive(:get).and_return(ActionDispatch::Response.new(200, {}, {company: company}.to_json, {}))
    allow_any_instance_of(Entities::SingletonIntegration).to receive(:get_external_entities).and_return(ext_company)
    allow_any_instance_of(Entities::SingletonIntegration).to receive(:update_external_entity).and_return(nil)
    allow(connec_client).to receive(:batch).and_return(ActionDispatch::Response.new(200, {}, {results: [{status: 200, body: {company: {id: [{provider: 'connec', id: 'some connec id'}]}}}]}.to_json, {}))
  }

  subject { Maestrano::Connector::Rails::SynchronizationJob.new.sync_entity('singleton_integration', organization, connec_client, external_client, nil, {}) }


  describe 'when no idmap' do

    describe 'when received both' do
      let(:company) { company_base.merge('id' => [{'id' => 'some connec id', 'provider' => 'connec', 'realm' => organization.uid}]) }
      let(:ext_company) { [ext_company_base] }

      context 'when connec most recent' do
        let(:connec_updated) { 1.second.ago }
        let(:batch_params) {
          {
            :sequential => true,
            :ops => [
              {
                :method => "put",
                :url => "/api/v2/#{organization.uid}/company/some connec id",
                :params => {
                  :company => {
                    id: [
                      {
                        :id => "ext comp id",
                        :provider => "provider",
                        :realm => "oauth uid"
                      }
                    ]
                  }
                }
              }
            ]
          }
        }

        it 'handles the get correctly' do
          expect_any_instance_of(Entities::SingletonIntegration).to receive(:consolidate_and_map_data).with([company], ext_company).and_return({connec_entities: [], external_entities: []})
          subject
        end

        it 'handles the idmap correctly' do
          expect{
            subject
          }.to change{ Maestrano::Connector::Rails::IdMap.count }.by(1)
          idmap = Maestrano::Connector::Rails::IdMap.last
          expect(idmap.name).to eql('My awesome company')
          expect(idmap.connec_entity).to eql('company')
          expect(idmap.external_entity).to eql('company')
          expect(idmap.message).to be_nil
          expect(idmap.external_id).to eql(ext_comp_id)
          expect(idmap.connec_id).to eql('some connec id')
        end

        it 'does the mapping correctly' do
          idmap = Entities::SingletonIntegration.create_idmap(organization_id: organization.id, external_id: ext_comp_id, connec_id: 'some connec id')
          allow(Entities::SingletonIntegration).to receive(:create_idmap).and_return(idmap)
          expect_any_instance_of(Entities::SingletonIntegration).to receive(:push_entities_to_external).with([{entity: {name: 'My awesome company'}, idmap: idmap}])
          subject
        end

        it 'send the external id to connec' do
          expect(connec_client).to receive(:batch).with(batch_params)
          subject
        end
      end

      context 'when external most recent' do
        let(:external_updated) { 1.second.ago }

        it 'handles the idmap correctly' do
          expect{
            subject
          }.to change{ Maestrano::Connector::Rails::IdMap.count }.by(1)
          idmap = Maestrano::Connector::Rails::IdMap.last
          expect(idmap.name).to eql('My not so awesome store')
          expect(idmap.connec_entity).to eql('company')
          expect(idmap.external_entity).to eql('company')
          expect(idmap.message).to be_nil
          expect(idmap.external_id).to eql(ext_comp_id)
        end

        it 'does the mapping correctly' do
          idmap = Entities::SingletonIntegration.create_idmap(organization_id: organization.id, external_id: ext_comp_id)
          allow(Entities::SingletonIntegration).to receive(:create_idmap).and_return(idmap)
          expect_any_instance_of(Entities::SingletonIntegration).to receive(:push_entities_to_connec).with([{entity: mapped_external_entity, idmap: idmap}])
          subject
        end
      end
    end
  end



  describe 'when idmap exists' do
    describe 'when received both' do
      let(:company) { company_base.merge('id' => [{'id' => ext_comp_id, 'provider' => provider, 'realm' => oauth_uid}, {'id' => 'connec-id', 'provider' => 'connec', 'realm' => 'some-realm'}]) }
      let(:ext_company) { [ext_company_base] }
      let!(:idmap) { Entities::SingletonIntegration.create_idmap(organization_id: organization.id, external_id: ext_comp_id) }

      context 'when connec most recent' do
        let(:connec_updated) { 1.second.ago }

        it 'handles the idmap correctly' do
          expect{
            subject
          }.to_not change{ Maestrano::Connector::Rails::IdMap.count }
          idmap = Maestrano::Connector::Rails::IdMap.last
          expect(idmap.name).to eql('My awesome company')
          expect(idmap.connec_entity).to eql('company')
          expect(idmap.external_entity).to eql('company')
          expect(idmap.message).to be_nil
          expect(idmap.external_id).to eql(ext_comp_id)
        end

        it 'does the mapping correctly' do
          expect_any_instance_of(Entities::SingletonIntegration).to receive(:push_entities_to_external).with([{entity: mapped_connec_entity, idmap: idmap}])
          subject
        end

        it 'does not map the external one' do
          expect_any_instance_of(Entities::SingletonIntegration).to_not receive(:map_to_connec)
          subject
        end
      end

      context 'when external most recent' do
        let(:external_updated) { 1.second.ago }

        it 'handles the idmap correctly' do
          expect{
            subject
          }.to_not change{ Maestrano::Connector::Rails::IdMap.count }
          idmap = Maestrano::Connector::Rails::IdMap.last
          expect(idmap.name).to eql('My not so awesome store')
          expect(idmap.connec_entity).to eql('company')
          expect(idmap.external_entity).to eql('company')
          expect(idmap.message).to be_nil
          expect(idmap.external_id).to eql(ext_comp_id)
        end

        it 'does the mapping correctly' do
          expect_any_instance_of(Entities::SingletonIntegration).to receive(:push_entities_to_connec).with([{entity: mapped_external_entity, idmap: idmap}])
          subject
        end

        it 'does not map the external one' do
          expect_any_instance_of(Entities::SingletonIntegration).to_not receive(:map_to_external)
          subject
        end
      end
    end
  end

  describe 'when received only connec one' do
    let(:company) { company_base.merge('id' => [{'id' => ext_comp_id, 'provider' => provider, 'realm' => oauth_uid}, {'id' => 'connec-id', 'provider' => 'connec', 'realm' => 'some-realm'}]) }
    let(:ext_company) { [] }
    let!(:idmap) { Entities::SingletonIntegration.create_idmap(organization_id: organization.id, external_id: ext_comp_id) }

    it 'handles the idmap correctly' do
      expect{
        subject
      }.to_not change{ Maestrano::Connector::Rails::IdMap.count }
      idmap = Maestrano::Connector::Rails::IdMap.last
      expect(idmap.name).to eql('My awesome company')
      expect(idmap.connec_entity).to eql('company')
      expect(idmap.external_entity).to eql('company')
      expect(idmap.message).to be_nil
      expect(idmap.external_id).to eql(ext_comp_id)
    end

    it 'does the mapping correctly' do
      expect_any_instance_of(Entities::SingletonIntegration).to receive(:push_entities_to_external).with([{entity: mapped_connec_entity, idmap: idmap}])
      subject
    end
  end

  describe 'when receive only external one' do
    let(:company) { [] }
    let(:ext_company) { [ext_company_base] }
    let!(:idmap) { Entities::SingletonIntegration.create_idmap(organization_id: organization.id, external_id: ext_comp_id) }

    it 'handles the idmap correctly' do
      expect{
        subject
      }.to_not change{ Maestrano::Connector::Rails::IdMap.count }
      idmap = Maestrano::Connector::Rails::IdMap.last
      expect(idmap.name).to eql('My not so awesome store')
      expect(idmap.connec_entity).to eql('company')
      expect(idmap.external_entity).to eql('company')
      expect(idmap.message).to be_nil
      expect(idmap.external_id).to eql(ext_comp_id)
    end

    it 'does the mapping correctly' do
      expect_any_instance_of(Entities::SingletonIntegration).to receive(:push_entities_to_connec).with([{entity: mapped_external_entity, idmap: idmap}])
      subject
    end
  end
end
