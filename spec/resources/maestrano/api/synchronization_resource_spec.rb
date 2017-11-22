# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Maestrano::Api::SynchronizationResource, type: :resource do
  let(:synchronization) { create(:synchronization) }
  subject { described_class.new(synchronization, {}) }

  # == Attributes ===========================================================
  it { is_expected.to have_attribute :status }
  it { is_expected.to have_attribute :message }
  it { is_expected.to have_attribute :updated_at }
  it { is_expected.to have_attribute :created_at }

  # == Filters ==============================================================
  it { is_expected.to filter(:uid) }
end
