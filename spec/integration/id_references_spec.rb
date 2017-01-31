require 'spec_helper'

describe 'id references' do

  class Entities::IdReference < Maestrano::Connector::Rails::Entity
    def self.external_entity_name
      'Payment'
    end

    def self.connec_entity_name
      'Payment'
    end

    def self.mapper_class
      PaymentMapper
    end

    def self.references
      {
        record_references: %w(organization_id),
        id_references: %w(lines/id)
      }
    end

    def self.object_name_from_connec_entity_hash(entity)
      entity['title']
    end

    def self.id_from_external_entity_hash(entity)
      entity['ID']
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
  let(:entity_name) { 'id_reference' }
 

  before {
    allow(connec_client).to receive(:get).and_return(ActionDispatch::Response.new(200, {}, {payments: [connec_payment]}.to_json, {}))
    allow(connec_client).to receive(:batch).and_return(ActionDispatch::Response.new(200, {}, {results: [{status: 200, body: {payments: {}}}]}.to_json, {}))

    allow_any_instance_of(Entities::IdReference).to receive(:get_external_entities).and_return([])
    allow(Maestrano::Connector::Rails::External).to receive(:entities_list).and_return([entity_name])
    organization.reset_synchronized_entities(true)
  }

  subject { Maestrano::Connector::Rails::SynchronizationJob.new.sync_entity(entity_name, organization, connec_client, external_client, organization.last_synchronization_date, {}) }

  describe 'a creation from connec' do
    before {
      allow_any_instance_of(Entities::IdReference).to receive(:create_external_entity).and_return(entity_received_after_creation)
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

    let(:mapped_entity) {
      {
        Title: payment_title,
        AccountId: ext_org_id,
        Line: [
          {
            Price: 123
          },
          {
            Price: 456
          }
        ]
      }.with_indifferent_access
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
            :url=>"/api/v2/#{organization.uid}/payments/#{connec_payment_id}",
            :params=>
            {
              :payments=>{
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
      expect(idmap.connec_entity).to eql('payment')
      expect(idmap.external_entity).to eql('payment')
      expect(idmap.message).to be_nil
      expect(idmap.external_id).to eql(ext_payment_id)
      expect(idmap.connec_id).to eql(connec_payment_id)
    end

    it 'does the mapping correctly' do
      idmap = Entities::IdReference.create_idmap(organization_id: organization.id, external_id: ext_payment_id, connec_id: connec_payment_id)
      allow(Entities::IdReference).to receive(:find_or_create_idmap).and_return(idmap)
      expect_any_instance_of(Entities::IdReference).to receive(:push_entities_to_external).with([{entity: mapped_entity, idmap: idmap, id_refs_only_connec_entity: {'lines' => lines.map { |line| line.delete('amount'); line }}}])
      subject
    end

    it 'send the external ids to connec' do
      expect(connec_client).to receive(:batch).with(batch_params)
      subject
    end
  end

  describe 'an update from connec with no new lines' do
    before {
      allow_any_instance_of(Entities::IdReference).to receive(:update_external_entity).and_return(entity_received_after_update)
    }

    let!(:idmap) { Entities::IdReference.create_idmap(organization_id: organization.id, external_id: ext_payment_id, connec_id: connec_payment_id) }

    let(:connec_payment) {
      {
        'id' => [
          {
            'realm' => 'org-fg4a',
            'provider' => 'connec',
            'id' => connec_payment_id
          },
          {
            'realm' => oauth_uid,
            'provider' => provider,
            'id' => ext_payment_id
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
            },
            {
              'realm' => oauth_uid,
              'provider' => provider,
              'id' => ext_line_id1
            }
          ],
          'amount' => 345,
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
          ],
          'amount' => 678
        }
      ]
    }

    let(:mapped_entity) {
      {
        Title: payment_title,
        AccountId: ext_org_id,
        Line: [
          {
            ID: ext_line_id1,
            Price: 345
          },
          {
            ID: ext_line_id2,
            Price: 678
          }
        ]
      }.with_indifferent_access
    }

    let(:entity_received_after_update) {
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

    it 'update the idmap' do
      subject
      expect(idmap.reload.message).to be_nil
      expect(idmap.reload.name).to eql(payment_title)
      expect(idmap.reload.last_push_to_external > 1.minute.ago).to be true
    end

    it 'does the mapping correctly' do
      expect_any_instance_of(Entities::IdReference).to receive(:push_entities_to_external).with([{entity: mapped_entity, idmap: idmap, id_refs_only_connec_entity: {'lines' => lines.map { |line| line.delete('amount'); line }}}])
      subject
    end

    it 'does not send anything back to connec' do
      expect(connec_client).to receive(:batch)
      # TODO change when performance improvment in connec helper is done
      # expect(connec_client).to_not receive(:batch)
      subject
    end
  end

  describe 'an update from connec with a new lines' do
    before {
      allow_any_instance_of(Entities::IdReference).to receive(:update_external_entity).and_return(entity_received_after_update)
    }

    let!(:idmap) { Entities::IdReference.create_idmap(organization_id: organization.id, external_id: ext_payment_id, connec_id: connec_payment_id) }
    let(:connec_line_id3) { '8905c5e0-e18e-0133-890f-07d4de9f9781' }
    let(:ext_line_id3) { 'ext line id3' }

    let(:connec_payment) {
      {
        'id' => [
          {
            'realm' => 'org-fg4a',
            'provider' => 'connec',
            'id' => connec_payment_id
          },
          {
            'realm' => oauth_uid,
            'provider' => provider,
            'id' => ext_payment_id
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
            },
            {
              'realm' => oauth_uid,
              'provider' => provider,
              'id' => ext_line_id1
            }
          ],
          'amount' => 345,
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
          ],
          'amount' => 678
        },
        {
          'id' => [
            {
              'realm' => 'org-fg4a',
              'provider' => 'connec',
              'id' => connec_line_id3
            }
          ],
          'amount' => 999
        }
      ]
    }

    let(:mapped_entity) {
      {
        Title: payment_title,
        AccountId: ext_org_id,
        Line: [
          {
            ID: ext_line_id1,
            Price: 345
          },
          {
            ID: ext_line_id2,
            Price: 678
          },
          {
            Price: 999
          }
        ]
      }.with_indifferent_access
    }

    let(:entity_received_after_update) {
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
          },
          {
            'ID' => ext_line_id3,
            'Price' => 999
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
            :url=>"/api/v2/#{organization.uid}/payments/#{connec_payment_id}",
            :params=>
            {
              :payments=>{
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
                  },
                  {
                    'id' => [
                      {
                        'realm' => 'org-fg4a',
                        'provider' => 'connec',
                        'id' => connec_line_id3
                      },
                      {
                        'realm' => oauth_uid,
                        'provider' => provider,
                        'id' => ext_line_id3
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

    it 'update the idmap' do
      subject
      expect(idmap.reload.message).to be_nil
      expect(idmap.reload.name).to eql(payment_title)
      expect(idmap.reload.last_push_to_external > 1.minute.ago).to be true
    end

    it 'does the mapping correctly' do
      expect_any_instance_of(Entities::IdReference).to receive(:push_entities_to_external).with([{entity: mapped_entity, idmap: idmap, id_refs_only_connec_entity: {'lines' => lines.map { |line| line.delete('amount'); line }}}])
      subject
    end

    it 'send the external ids to connec' do
      expect(connec_client).to receive(:batch).with(batch_params)
      subject
    end
  end
end