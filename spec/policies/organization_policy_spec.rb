# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Maestrano::Connector::Rails::OrganizationPolicy do
  let(:klass) { described_class.to_s.gsub('Policy', '').constantize }
  let!(:user) { create(:user, tenant: 'default') }
  let!(:org1) { create(:organization, tenant: 'default') }
  let!(:org2) { create(:organization, tenant: 'production') }
  let(:scope) { klass.all }

  context 'for a user who has access to the first org' do
    subject { described_class::Scope.new(user.tenant, scope).resolve }

    it 'shows the first org' do
      expect(subject).to eq [org1]
    end
  end
end
