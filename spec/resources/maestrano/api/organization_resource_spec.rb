# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Maestrano::Api::OrganizationResource, type: :resource do
  let(:organization) { create(:organization, synchronized_entities: {}) }
  subject { described_class.new(organization, {}) }
  before { allow(Maestrano::Connector::Rails::External).to receive(:create_account_link).and_return('www.maestrano.com') }

  # == Attributes ===========================================================
  it { is_expected.to have_attribute :has_account_linked }
  it { is_expected.to have_attribute :name }
  it { is_expected.to have_attribute :uid }
  it { is_expected.to have_attribute :org_uid }
  it { is_expected.to have_attribute :account_creation_link }
  it { is_expected.to have_attribute :displayable_synchronized_entities }
  it { is_expected.to have_attribute :date_filtering_limit }
  it { is_expected.to have_attribute :tenant }
  it { is_expected.to have_attribute :provider }
  it { is_expected.to have_attribute :sync_enabled }
  it { is_expected.to have_attribute :entities_types }

  # == Filters ==============================================================
  it { is_expected.to filter(:uid) }
end
