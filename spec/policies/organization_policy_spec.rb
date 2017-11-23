# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Maestrano::Connector::Rails::OrganizationPolicy do
  include SharedPunditExample

  let!(:instance1) { create(:organization, tenant: 'default') }
  let!(:instance2) { create(:organization, tenant: 'production') }

  describe 'scope' do
    it_behaves_like 'a model scoped to the tenant'
  end

  describe 'policy' do
    let!(:user) { create(:user, tenant: 'default') }

    subject { described_class.new(user.tenant, instance1) }

    it { is_expected.to permit_new_and_create_actions }
    it { is_expected.to permit_edit_and_update_actions }
  end
end
