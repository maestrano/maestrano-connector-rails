# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Maestrano::Connector::Rails::SynchronizationPolicy do
  include SharedPunditExample

  let!(:org1) { create(:organization, tenant: 'default') }
  let!(:org2) { create(:organization, tenant: 'production') }
  let!(:instance1) { create(:synchronization, organization: org1) }
  let!(:instance2) { create(:synchronization, organization: org2) }

  describe 'scope' do
    it_behaves_like 'a model scoped to the tenant'
  end

  describe 'policy' do
    let!(:user) { create(:user, tenant: 'default') }

    subject { described_class.new(user.tenant, instance1) }

    it { is_expected.to forbid_new_and_create_actions }
    it { is_expected.to forbid_edit_and_update_actions }
  end
end
