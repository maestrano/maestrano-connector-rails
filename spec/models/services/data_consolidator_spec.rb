require 'spec_helper'

def process_entities_to_cmp(entities)
  entities.flat_map {|e| e[:entity]["id"] = e[:entity]["id"].first["id"]; e[:entity]}
end

describe Maestrano::Connector::Rails::Services::DataConsolidator do
  let!(:organization) {create(:organization, uid: 'cld-123')}
  let(:external_entities) {
    [
      {
        "amount" => 8.93,
        "type" => "RECEIVE",
        "public_note" => "",
        "transaction_date" => "2018-07-31 12:00:00 +0000",
        "name" => "INTEREST PAYMENT",
        "id" => "TX8934077941420180731",
        "account_id" => "4518736"
      },
      {
        "amount" => -26.47,
        "type" => "SPEND",
        "public_note" => "DISBURSEMENT TO MORTGAGOR",
        "transaction_date" => "2018-01-16 12:00:00 +0000",
        "name" => "DISBURSEMENT TO MORTGAGOR",
        "id" => "201801160",
        "account_id" => "4518738"
      },
      {
        "amount" => 25.0,
        "type" => "RECEIVE",
        "public_note" => "LATE CHARGE PAID",
        "transaction_date" => "2018-01-12 12:00:00 +0000",
        "name" => "LATE CHARGE PAID",
        "id" => "201801121",
        "account_id" => "4518738"
      }
    ]
  }

  class BankTransactionMapper
    extend HashMapper
    map from('name'), to('name')
    map from('transaction_date'), to('transaction_date')
    map from('type'), to('type')
    map from('public_note'), to('public_note')
    map from('account_id'), to('account_id')
    map from('id'), to('id')
    map from('lines'), to('lines')
    map from('status'), to('status')
    map from('amount'), to('amount')
  end

  class BankTransaction < Maestrano::Connector::Rails::Entity
    def self.id_from_external_entity_hash(entity)
      entity["id"]
    end

    def self.connec_entity_name
      'Transaction'
    end

    # Entity name in external system
    def self.external_entity_name
      'Transaction'
    end

    def self.object_name_from_external_entity_hash(entity)
      self.id_from_external_entity_hash(entity)
    end

    def self.mapper_class
      BankTransactionMapper
    end
  end

  describe 'consolidate_external_entities' do
    it 'should return all external entities' do
      transaction = BankTransaction.new(organization, nil, nil)
      allow(BankTransaction).to receive(:immutable?).and_return(false)
      data_consolidator = Maestrano::Connector::Rails::Services::DataConsolidator.new(organization, transaction, {})
      entities = data_consolidator.consolidate_external_entities(external_entities, 'BankTransaction')
      ent = process_entities_to_cmp(entities)
      expect(ent).to eq(external_entities)
    end

    it 'should return some external entities' do
      Maestrano::Connector::Rails::IdMap.create(external_id: "TX8934077941420180731", external_entity: 'transaction', organization_id: organization.id, connec_entity: 'banktransaction', connec_id: 1)
      transaction = BankTransaction.new(organization, nil, nil)
      allow(BankTransaction).to receive(:immutable?).and_return(true)
      data_consolidator = Maestrano::Connector::Rails::Services::DataConsolidator.new(organization, transaction, {})
      entities = data_consolidator.consolidate_external_entities(external_entities, 'BankTransaction')
      ent = process_entities_to_cmp(entities)
      expect(ent.count).to eq(2)
      expect(ent[0]).to eq(external_entities[1])
      expect(ent[1]).to eq(external_entities[2])
    end

    it 'should return empty array' do
      Maestrano::Connector::Rails::IdMap.create(external_id: "TX8934077941420180731", external_entity: 'transaction', organization_id: organization.id, connec_entity: 'banktransaction', connec_id: 1)
      Maestrano::Connector::Rails::IdMap.create(external_id: "201801160", external_entity: 'transaction', organization_id: organization.id, connec_entity: 'banktransaction', connec_id: 2)
      Maestrano::Connector::Rails::IdMap.create(external_id: "201801121", external_entity: 'transaction', organization_id: organization.id, connec_entity: 'banktransaction', connec_id: 3)
      transaction = BankTransaction.new(organization, nil, nil)
      allow(BankTransaction).to receive(:immutable?).and_return(true)
      data_consolidator = Maestrano::Connector::Rails::Services::DataConsolidator.new(organization, transaction, {})
      entities = data_consolidator.consolidate_external_entities(external_entities, 'BankTransaction')
      expect(entities.count).to eq(0)
    end
  end
end

