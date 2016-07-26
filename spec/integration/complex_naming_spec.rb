require 'spec_helper'

describe 'complex entity subentities naming conflict' do

  class Entities::NamePayment < Maestrano::Connector::Rails::ComplexEntity
    def self.connec_entities_names
      {Payment: 'NamePayment'}
    end
    def self.external_entities_names
      {Payment: 'ExtPayment'}
    end
    def connec_model_to_external_model(connec_hash_of_entities)
      {'Payment' => {'Payment' => connec_hash_of_entities['Payment']}}
    end
    def external_model_to_connec_model(external_hash_of_entities)
      {'Payment' => {'Payment' => external_hash_of_entities['Payment']}}
    end
  end

  module Entities::SubEntities
  end
  class Entities::SubEntities::NamePayment < Maestrano::Connector::Rails::SubEntityBase
    def self.external?
      false
    end
    def self.entity_name
      'Payment'
    end
    def self.mapper_classes
      {
        'Payment' => ::PaymentMapper
      }
    end
    def self.object_name_from_connec_entity_hash(entity)
      entity['title']
    end
    def self.references
      {'Payment' => {record_references: %w(organization_id), id_references: %w(lines/id)}}
    end
    def self.id_from_external_entity_hash(entity)
      entity['ID']
    end
  end

  class Entities::SubEntities::ExtPayment < Maestrano::Connector::Rails::SubEntityBase
    def self.external?
      true
    end
    def self.entity_name
      'Payment'
    end
    def self.mapper_classes
      {'Payment' => ::PaymentMapper}
    end
    def self.id_from_external_entity_hash(entity)
      entity['ID']
    end
    def self.references
      {'Payment' => {record_references: %w(organization_id), id_references: %w(lines/id)}}
    end
  end

  class LineMapper
    extend HashMapper
    map from('id'), to('ID')
    map from('amount'), to('Price')
  end

  class PaymentMapper
    extend HashMapper
    map from('title'), to('Title')
    map from('organization_id'), to('AccountId')
    map from('lines'), to('Line'), using: LineMapper
  end

  let(:provider) { 'provider' }
  let(:oauth_uid) { 'oauth uid' }
  let!(:organization) { create(:organization, oauth_provider: provider, oauth_uid: oauth_uid) }
  let(:connec_client) { Maestrano::Connector::Rails::ConnecHelper.get_client(organization) }
  let(:external_client) { Object.new }
  let(:connec_payment_id) { '1205c5e0-e18e-0133-890f-07d4de9f9781' }
  let(:connec_line_id1) { '3405c5e0-e18e-0133-890f-07d4de9f9781' }
  let(:ext_payment_id) { 'ext payment id' }
  let(:ext_org_id) { 'ext org id' }
  let(:ext_line_id1) { 'ext line id1' }
  let(:payment_title) { 'This is a payment' }

  before {
    allow(Maestrano::Connector::Rails::External).to receive(:entities_list).and_return(%w(name_payment))
  }

  subject { Maestrano::Connector::Rails::SynchronizationJob.new.sync_entity('name_payment', organization, connec_client, external_client, organization.last_synchronization_date, {}) }

  describe 'fetching entities from external' do
    before {
      allow_any_instance_of(Entities::SubEntities::NamePayment).to receive(:get_connec_entities).and_return([])
    }

    it 'does a fetch with the right name' do
      expect_any_instance_of(Entities::SubEntities::ExtPayment).to receive(:get_external_entities).with('Payment', organization.last_synchronization_date).and_return([])
      subject
    end
  end

  describe 'sending entities to external' do
    before {
      allow(connec_client).to receive(:get).and_return(ActionDispatch::Response.new(200, {}, {payments: [connec_payment]}.to_json, {}))
      allow(connec_client).to receive(:batch).and_return(ActionDispatch::Response.new(200, {}, {results: [{status: 200, body: {payments: {}}}]}.to_json, {}))

      allow_any_instance_of(Entities::SubEntities::ExtPayment).to receive(:get_external_entities).and_return([])
    }

    let(:connec_payment) {
      {
        'id' => [
          {
            'realm' => 'org-fg4a',
            'provider' => 'connec',
            'id' => connec_payment_id
          }
        ],
        'title' => payment_title,
        'organization_id' => [
          {
            'realm' => 'org-fg4a',
            'provider' => 'connec',
            'id' => '2305c5e0-e18e-0133-890f-07d4de9f9781'
          },
          {
            'realm' => oauth_uid,
            'provider' => provider,
            'id' => ext_org_id
          }
        ],
        'lines' => lines
      }
    }

    let(:lines) {
      [
        {
          'id' => [
            {
              'realm' => 'org-fg4a',
              'provider' => 'connec',
              'id' => connec_line_id1
            }
          ],
          'amount' => 123
        }
      ]
    }

    let(:mapped_payment) {
      {
        "Title"=>"This is a payment",
        "AccountId"=>"ext org id",
        "Line"=>[{"Price"=>123}]}
    }

    before {
      allow_any_instance_of(Entities::SubEntities::NamePayment).to receive(:create_external_entity).and_return({'ID' => ext_payment_id})
    }

    it 'handles the idmap correctly' do
      expect{
        subject
      }.to change{ Maestrano::Connector::Rails::IdMap.count }.by(1)
      idmap = Maestrano::Connector::Rails::IdMap.last
      expect(idmap.name).to eql(payment_title)
      expect(idmap.connec_entity).to eql('payment')
      expect(idmap.external_entity).to eql('payment')
      expect(idmap.message).to be_nil
      expect(idmap.external_id).to eql(ext_payment_id)
      expect(idmap.connec_id).to eql(connec_payment_id)
    end

    it 'handles the mapping correctly' do
      payment_idmap = Entities::SubEntities::NamePayment.create_idmap(organization_id: organization.id, external_id: ext_payment_id, connec_entity: 'payment')
      allow(Maestrano::Connector::Rails::IdMap).to receive(:create).and_return(payment_idmap)
      expect_any_instance_of(Entities::NamePayment).to receive(:push_entities_to_external).with({'Payment' => {'Payment' => [{entity: mapped_payment.with_indifferent_access, idmap: payment_idmap, id_refs_only_connec_entity: {'lines' => lines.map { |l| l.delete('amount'); l }}}]}})
      subject
    end

    it 'handles the sending with the correct names' do
      expect_any_instance_of(Entities::SubEntities::NamePayment).to receive(:create_external_entity).once.with(mapped_payment, 'Payment').and_return({})
      expect(connec_client).to receive(:batch).once.and_return(ActionDispatch::Response.new(201, {}, {results: []}.to_json, {}))
      subject
    end
  end
end