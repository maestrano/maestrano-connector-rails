require 'spec_helper'

describe 'complex entities workflow' do
  class Entities::CustomerAndSupplier < Maestrano::Connector::Rails::ComplexEntity
    def self.connec_entities_names
      %w(CompOrganization)
    end
    def self.external_entities_names
      %w(CompCustomer CompSupplier)
    end
    def connec_model_to_external_model(connec_hash_of_entities)
      organizations = connec_hash_of_entities['CompOrganization']
      modelled_connec_entities = {'CompOrganization' => { 'CompSupplier' => [], 'CompCustomer' => [] }}

      organizations.each do |organization|
        if organization['is_supplier']
          modelled_connec_entities['CompOrganization']['CompSupplier'] << organization
        else
          modelled_connec_entities['CompOrganization']['CompCustomer'] << organization
        end
      end
      return modelled_connec_entities
    end
    def external_model_to_connec_model(external_hash_of_entities)
      return {'CompCustomer' => {'CompOrganization' => external_hash_of_entities['CompCustomer']}, 'CompSupplier' => {'CompOrganization' => external_hash_of_entities['CompSupplier']}}
    end
  end

  module Entities::SubEntities
  end
  class Entities::SubEntities::CompOrganization < Maestrano::Connector::Rails::SubEntityBase
    def self.external?
      false
    end
    def self.entity_name
      'CompOrganization'
    end
    def self.mapper_classes
      {
        'CompCustomer' => ::CompMapper,
        'CompSupplier' => ::CompMapper
      }
    end
    def self.object_name_from_connec_entity_hash(entity)
      entity['name']
    end
    def self.references
      {'CompCustomer' => ['ref_id'], 'CompSupplier' => ['ref_id']}
    end
    def self.id_from_external_entity_hash(entity)
      entity['id']
    end
  end

  class Entities::SubEntities::CompCustomer < Maestrano::Connector::Rails::SubEntityBase
    def self.external?
      true
    end
    def self.entity_name
      'CompCustomer'
    end
    def self.mapper_classes
      {'CompOrganization' => ::CompMapper}
    end
    def self.id_from_external_entity_hash(entity)
      entity['id']
    end
    def self.object_name_from_external_entity_hash(entity)
      entity['name']
    end
    def self.references
      {'CompOrganization' => ['ref_id']}
    end
    def map_to(name, entity)
      super.merge(is_supplier: false)
    end
  end
  class Entities::SubEntities::CompSupplier < Maestrano::Connector::Rails::SubEntityBase
    def self.external?
      true
    end
    def self.entity_name
      'CompSupplier'
    end
    def self.mapper_classes
      {'CompOrganization' => ::CompMapper}
    end
    def self.id_from_external_entity_hash(entity)
      entity['id']
    end
    def self.object_name_from_external_entity_hash(entity)
      entity['name']
    end
    def self.references
      {'CompOrganization' => ['ref_id']}
    end
    def map_to(name, entity)
      super.merge(is_supplier: true)
    end
  end

  class CompMapper
    extend HashMapper
    map from('id'), to('id')
    map from('ref_id'), to('ref_id')
    map from('name'), to('name')
  end

  let(:provider) { 'provider' }
  let(:oauth_uid) { 'oauth uid' }
  let!(:organization) { create(:organization, oauth_provider: provider, oauth_uid: oauth_uid, uid: 'uid') }
  let(:connec_client) { Maestrano::Connec::Client[organization.tenant].new(organization.uid) }
  let(:external_client) { Object.new }


  let(:connec_org1_id) { 'connec_org1_id' }
  let(:connec_org2_id) { 'connec_org2_id' }
  let(:connec_org1_ext_id) { 'connec_org1_ext_id' }
  let(:connec_org2_ext_id) { 'connec_org2_ext_id' }
  let(:connec_org1_name) { 'connec_org1_name' }
  let(:connec_org2_name) { 'connec_org2_name' }
  let(:connec_org1_ext_ref_id) { 'connec_org1_ext_ref_id' }
  let(:connec_org2_ext_ref_id) { 'connec_org2_ext_ref_id' }
  let(:connec_org1) {
    {
      'id' => [{'provider' => 'connec', 'id' => connec_org1_id, 'realm' => organization.uid}],
      'name' => connec_org1_name,
      'is_supplier' => true,
      'ref_id' => [{'provider' => provider, 'id' => connec_org1_ext_ref_id, 'realm' => oauth_uid}]
    }
  }
  let(:mapped_connec_org1) {
    {
      ref_id: connec_org1_ext_ref_id,
      name: connec_org1_name,
    }
  }
  let(:connec_org2) {
    {
      'id' => [{'provider' => provider, 'id' => connec_org2_ext_id, 'realm' => oauth_uid}, {'id' => connec_org2_id, 'provider' => 'connec', 'realm' => organization.uid}],
      'name' => connec_org2_name,
      'is_supplier' => false,
      'ref_id' => [{'provider' => provider, 'id' => connec_org2_ext_ref_id, 'realm' => oauth_uid}]
    }
  }
  let(:mapped_connec_org2) {
    {
      ref_id: connec_org2_ext_ref_id,
      name: connec_org2_name,
      id: connec_org2_ext_id
    }
  }
  let(:connec_orgs) { [connec_org1, connec_org2] }

  let(:ext_customer_id) { 'ext_customer_id' }
  let(:ext_supplier_id) { 'ext_supplier_id' }
  let(:ext_customer_name) { 'ext_customer_name' }
  let(:ext_supplier_name) { 'ext_supplier_name' }
  let(:ext_ref_id) { 'ext_ref_id' }
  let(:ext_customer) {
    {
      'id' => ext_customer_id,
      'name' => ext_customer_name,
      'ref_id' => ext_ref_id
    }
  }
  let(:mapped_ext_customer) {
    {
      :id => [
        {
          :id => ext_customer_id,
          :provider => provider,
          :realm => oauth_uid
        }
      ],
      :ref_id => [
        {
          :id => ext_ref_id,
          :provider => provider,
          :realm => oauth_uid
        }
      ],
      :name => ext_customer_name,
      :is_supplier => false
    }
  }
  let(:ext_supplier) {
    {
      'id' => ext_supplier_id,
      'name' => ext_supplier_name,
      'ref_id' => ext_ref_id
    }
  }
  let(:mapped_ext_supplier) {
    {
      :id => [
        {
          :id => ext_supplier_id,
          :provider => provider,
          :realm => oauth_uid
        }
      ],
      :ref_id => [
        {
          :id => ext_ref_id,
          :provider => provider,
          :realm => oauth_uid
        }
      ],
      :name => ext_supplier_name,
      :is_supplier => true
    }
  }
  let!(:supplier_idmap) { Entities::SubEntities::CompSupplier.create_idmap(organization_id: organization.id, external_id: ext_supplier_id, connec_entity: 'comporganization') }

  before {
    allow(connec_client).to receive(:get).and_return(ActionDispatch::Response.new(200, {}, {comporganizations: connec_orgs}.to_json, {}))
    allow_any_instance_of(Entities::SubEntities::CompCustomer).to receive(:get_external_entities).and_return([ext_customer])
    allow_any_instance_of(Entities::SubEntities::CompSupplier).to receive(:get_external_entities).and_return([ext_supplier])
  }

  subject { Maestrano::Connector::Rails::SynchronizationJob.new.sync_entity('customer_and_supplier', organization, connec_client, external_client, nil, {}) }

  it 'handles the fetching correctly' do
    expect_any_instance_of(Entities::CustomerAndSupplier).to receive(:consolidate_and_map_data).with({'CompOrganization' => connec_orgs}, {'CompCustomer' => [ext_customer], 'CompSupplier' => [ext_supplier]}).and_return({connec_entities: [], external_entities: []})
    subject
  end

  it 'handles the idmap correctly' do
    allow(connec_client).to receive(:batch).and_return(ActionDispatch::Response.new(201, {}, {results: []}.to_json, {}))
    allow_any_instance_of(Entities::SubEntities::CompOrganization).to receive(:create_external_entity).and_return({'id' => connec_org1_ext_id})
    allow_any_instance_of(Entities::SubEntities::CompOrganization).to receive(:update_external_entity).and_return(nil)
    expect{
      subject
    }.to change{ Maestrano::Connector::Rails::IdMap.count }.by(3)

    expect(supplier_idmap.reload.name).to eql(ext_supplier_name)
    expect(supplier_idmap.reload.connec_entity).to eql('comporganization')
    expect(supplier_idmap.reload.external_entity).to eql('compsupplier')
    expect(supplier_idmap.reload.message).to be_nil
    expect(supplier_idmap.reload.external_id).to eql(ext_supplier_id)

    customer_idmap = Entities::SubEntities::CompCustomer.find_idmap({external_id: ext_customer_id})
    expect(customer_idmap).to_not be_nil
    expect(customer_idmap.name).to eql(ext_customer_name)
    expect(customer_idmap.connec_entity).to eql('comporganization')
    expect(customer_idmap.external_entity).to eql('compcustomer')
    expect(customer_idmap.message).to be_nil

    org1_idmap = Entities::SubEntities::CompOrganization.find_idmap({external_id: connec_org1_ext_id})
    expect(org1_idmap).to_not be_nil
    expect(org1_idmap.name).to eql(connec_org1_name)
    expect(org1_idmap.connec_entity).to eql('comporganization')
    expect(org1_idmap.external_entity).to eql('compsupplier')
    expect(org1_idmap.message).to be_nil

    org2_idmap = Entities::SubEntities::CompOrganization.find_idmap({external_id: connec_org2_ext_id})
    expect(org2_idmap).to_not be_nil
    expect(org2_idmap.name).to eql(connec_org2_name)
    expect(org2_idmap.connec_entity).to eql('comporganization')
    expect(org2_idmap.external_entity).to eql('compcustomer')
    expect(org2_idmap.message).to be_nil
  end

  it 'handles the mapping correctly' do
    cust_idmap = Entities::SubEntities::CompCustomer.create_idmap(organization_id: organization.id, external_id: ext_customer_id, connec_entity: 'comporganization')
    org1_idmap = Entities::SubEntities::CompOrganization.create_idmap(organization_id: organization.id, external_id: connec_org1_ext_id, external_entity: 'compsupplier')
    org2_idmap = Entities::SubEntities::CompOrganization.create_idmap(organization_id: organization.id, external_id: connec_org2_ext_id, external_entity: 'compcustomer')
    allow(Maestrano::Connector::Rails::IdMap).to receive(:create).and_return(org1_idmap, org2_idmap, cust_idmap)
    expect_any_instance_of(Entities::CustomerAndSupplier).to receive(:push_entities_to_external).with({'CompOrganization' => {'CompSupplier' => [{entity: mapped_connec_org1.with_indifferent_access, idmap: org1_idmap, id_refs_only_connec_entity: {}}], 'CompCustomer' => [{entity: mapped_connec_org2.with_indifferent_access, idmap: org2_idmap, id_refs_only_connec_entity: {}}]}})
    expect_any_instance_of(Entities::CustomerAndSupplier).to receive(:push_entities_to_connec).with({'CompCustomer' => {'CompOrganization' => [{entity: mapped_ext_customer.with_indifferent_access, idmap: cust_idmap}]}, 'CompSupplier' => {'CompOrganization' => [{entity: mapped_ext_supplier.with_indifferent_access, idmap: supplier_idmap}]}})
    subject
  end

  it 'sends two objects to connec, two objects to external and send back one id to connec' do
    expect_any_instance_of(Entities::SubEntities::CompOrganization).to receive(:create_external_entity).once.with(mapped_connec_org1, 'CompSupplier').and_return({})
    expect_any_instance_of(Entities::SubEntities::CompOrganization).to receive(:update_external_entity).once.with(mapped_connec_org2, connec_org2_ext_id, 'CompCustomer')
    expect(connec_client).to receive(:batch).exactly(3).times.and_return(ActionDispatch::Response.new(201, {}, {results: []}.to_json, {}), ActionDispatch::Response.new(200, {}, {results: []}.to_json, {}))
    subject
  end
end
