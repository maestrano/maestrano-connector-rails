require 'spec_helper'

describe Maestrano::Connector::Rails::AllSynchronizationsJob do
  let(:organization_not_linked) { create(:organization, oauth_provider: 'salesforce', oauth_token: nil, sync_enabled: true) }
  let(:organization_not_active) { create(:organization, oauth_provider: 'salesforce', oauth_token: '123', sync_enabled: 0) }
  let(:organization_to_process) { create(:organization, oauth_provider: 'salesforce', oauth_token: '123', sync_enabled: true) }

  subject { Maestrano::Connector::Rails::AllSynchronizationsJob.perform_now() }

  # before{
  #   organization_not_active.update(encrypted_oauth_token: Maestrano::Connector::Rails::Organization.encrypt_oauth_token('123', key: 'This is a key that is 256 bits!!', iv: 'This iv is 12 bytes or longer'))
  #   organization_to_process.update(encrypted_oauth_token: Maestrano::Connector::Rails::Organization.encrypt_oauth_token('123', key: 'This is a key that is 256 bits!!', iv: 'This iv is 12 bytes or longer'))
  # }

  describe 'perform' do
    it 'does not calls sync entity' do
      expect(Maestrano::Connector::Rails::SynchronizationJob).to_not receive(:perform_later).with(organization_not_linked.id, anything)
      expect(Maestrano::Connector::Rails::SynchronizationJob).to_not receive(:perform_later).with(organization_not_active.id, anything)
      expect(Maestrano::Connector::Rails::SynchronizationJob).to receive(:perform_later).with(organization_to_process.id, anything)

      subject
    end
  end
end
