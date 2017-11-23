# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Maestrano::Api::UserResource, type: :resource do
  let(:user) { create(:user) }
  subject { described_class.new(user, {}) }

  # == Attributes ===========================================================
  it { is_expected.to have_attribute :first_name }
  it { is_expected.to have_attribute :provider }
  it { is_expected.to have_attribute :last_name }
  it { is_expected.to have_attribute :email }
  it { is_expected.to have_attribute :tenant }
  it { is_expected.to have_attribute :uid }
end
