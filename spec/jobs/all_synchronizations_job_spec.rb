require 'spec_helper'

describe Maestrano::Connector::Rails::AllSynchronizationsJob do
  let(:organization_not_linked) { create(:organization, oauth_provider: 'salesforce', oauth_token: nil, sync_enabled: true) }
  let(:organization_not_active) { create(:organization, oauth_provider: 'salesforce', oauth_token: '123', sync_enabled: 0) }
  let(:organization_to_process) { create(:organization, oauth_provider: 'salesforce', oauth_token: '123', sync_enabled: true) }

  subject { Maestrano::Connector::Rails::AllSynchronizationsJob.perform_now() }

  describe 'perform' do
    it 'does not calls sync entity' do
      expect { subject }.to enqueue_job(Maestrano::Connector::Rails::SynchronizationJob).with(organization_to_process.id, anything)
    end
  end
end
