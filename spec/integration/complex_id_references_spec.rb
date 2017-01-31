require 'spec_helper'

describe 'complex id references' do

  class Entities::IdPayment < Maestrano::Connector::Rails::ComplexEntity
    def self.connec_entities_names
      %w(IdPayment)
    end
    def self.external_entities_names
      %w(IdBill)
    end
    def connec_model_to_external_model(connec_hash_of_entities)
      {'IdPayment' => {'IdBill' => connec_hash_of_entities['IdPayment']}}
    end
    def external_model_to_connec_model(external_hash_of_entities)
      {'IdBill' => {'IdPayment' => external_hash_of_entities['IdBill']}}
    end
  end

  module Entities::SubEntities
  end
  class Entities::SubEntities::IdPayment < Maestrano::Connector::Rails::SubEntityBase
    def self.external?
      false
    end
    def self.entity_name
      'IdPayment'
    end
    def self.mapper_classes
      {
        'IdBill' => ::IdPaymentMapper
      }
    end
    def self.object_name_from_connec_entity_hash(entity)
      entity['title']
    end
    def self.references
      {'IdBill' => {record_references: %w(organization_id), id_references: %w(lines/id)}}
    end
    def self.id_from_external_entity_hash(entity)
      entity['ID']
    end
  end

  class Entities::SubEntities::IdBill < Maestrano::Connector::Rails::SubEntityBase
    def self.external?
      true
    end
    def self.entity_name
      'IdBill'
    end
    def self.mapper_classes
      {'IdPayment' => ::IdPaymentMapper}
    end
    def self.id_from_external_entity_hash(entity)
      entity['ID']
    end
    def self.references
      {'IdPayment' => {record_references: %w(organization_id), id_references: %w(lines/id)}}
    end
  end

  class IdLineMapper
    extend HashMapper
    map from('id'), to('ID')
    map from('amount'), to('Price')
  end

  class IdPaymentMapper
    extend HashMapper
    map from('title'), to('Title')
    map from('organization_id'), to('AccountId')
    map from('lines'), to('Line'), using: IdLineMapper
  end

  let(:provider) { 'provider' }
  let(:oauth_uid) { 'oauth uid' }
  let!(:organization) { create(:organization, oauth_provider: provider, oauth_uid: oauth_uid) }
  let(:connec_client) { Maestrano::Connector::Rails::ConnecHelper.get_client(organization) }
  let(:external_client) { Object.new }
  let(:connec_payment_id) { '1205c5e0-e18e-0133-890f-07d4de9f9781' }
  let(:connec_line_id1) { '3405c5e0-e18e-0133-890f-07d4de9f9781' }
  let(:connec_line_id2) { '4505c5e0-e18e-0133-890f-07d4de9f9781' }
  let(:ext_payment_id) { 'ext payment id' }
  let(:ext_org_id) { 'ext org id' }
  let(:ext_line_id1) { 'ext line id1' }
  let(:ext_line_id2) { 'ext line id2' }

  let(:payment_title) { 'This is a payment' }

  before {
    allow(Maestrano::Connector::Rails::External).to receive(:entities_list).and_return(%w(id_payment))
    organization.reset_synchronized_entities(true)

    allow(connec_client).to receive(:get).and_return(ActionDispatch::Response.new(200, {}, {idpayments: [connec_payment]}.to_json, {}))
    allow(connec_client).to receive(:batch).and_return(ActionDispatch::Response.new(200, {}, {results: [{status: 200, body: {payments: {}}}]}.to_json, {}))

    allow_any_instance_of(Entities::SubEntities::IdBill).to receive(:get_external_entities).and_return([])
  }

  subject { Maestrano::Connector::Rails::SynchronizationJob.new.sync_entity('id_payment', organization, connec_client, external_client, organization.last_synchronization_date, {}) }

  describe 'a creation from connec' do
    before {
      allow_any_instance_of(Entities::SubEntities::IdPayment).to receive(:create_external_entity).and_return(entity_received_after_creation)
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
        },
        {
          'id' => [
            {
              'realm' => 'org-fg4a',
              'provider' => 'connec',
              'id' => connec_line_id2
            }
          ],
          'amount' => 456
        }
      ]
    }

    let(:entity_received_after_creation) {
      {
        'ID' => ext_payment_id,
        'Title' => payment_title,
        'AccountId' => ext_org_id,
        'Line' => [
          {
            'ID' => ext_line_id1,
            'Price' => 123
          },
          {
            'ID' => ext_line_id2,
            'Price' => 456
          }
        ]
      }
    }

    let(:batch_params) {
      {
        :sequential=>true,
        :ops=> [
          {
            :method=>"put",
            :url=>"/api/v2/#{organization.uid}/idpayments/#{connec_payment_id}",
            :params=>
            {
              :idpayments=>{
                'id' => [
                  {
                    'id' => ext_payment_id,
                    'provider' =>provider,
                    'realm' =>oauth_uid
                  }
                ],
                'lines' => [
                  {
                    'id' => [
                      {
                        'realm' => 'org-fg4a',
                        'provider' => 'connec',
                        'id' => connec_line_id1
                      },
                      {
                        'realm' => oauth_uid,
                        'provider' => provider,
                        'id' => ext_line_id1
                      }
                    ]
                  },
                  {
                    'id' => [
                      {
                        'realm' => 'org-fg4a',
                        'provider' => 'connec',
                        'id' => connec_line_id2
                      },
                      {
                        'realm' => oauth_uid,
                        'provider' => provider,
                        'id' => ext_line_id2
                      }
                    ]
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
      expect(idmap.name).to eql(payment_title)
      expect(idmap.connec_entity).to eql('idpayment')
      expect(idmap.external_entity).to eql('idbill')
      expect(idmap.message).to be_nil
      expect(idmap.external_id).to eql(ext_payment_id)
      expect(idmap.connec_id).to eql(connec_payment_id)
    end

    it 'send the external id to connec' do
      expect(connec_client).to receive(:batch).with(batch_params)
      subject
    end
  end
end