require 'spec_helper'

describe Maestrano::Connector::Rails::AllSynchronizationsJob do
  let(:organization_not_linked) { create(:organization, oauth_provider: 'salesforce', oauth_token: nil, sync_enabled: true) }
  let(:organization_not_active) { create(:organization, oauth_provider: 'salesforce', oauth_token: '123', sync_enabled: 0) }
  let(:organization_to_process) { create(:organization, oauth_provider: 'salesforce', oauth_token: '123', sync_enabled: true) }

  subject { Maestrano::Connector::Rails::AllSynchronizationsJob.perform_now() }

  describe 'perform' do
    it 'does not calls sync entity' do
      expect(Maestrano::Connector::Rails::SynchronizationJob).to_not receive(:perform_later).with(organization_not_linked, anything)
      expect(Maestrano::Connector::Rails::SynchronizationJob).to_not receive(:perform_later).with(organization_not_active, anything)
      expect(Maestrano::Connector::Rails::SynchronizationJob).to receive(:perform_later).with(organization_to_process, anything)

      subject
    end
  end
end
