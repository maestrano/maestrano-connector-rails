# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Maestrano::Api::IdMapResource, type: :resource do
  let(:id_map) { create(:idmap) }
  subject { described_class.new(id_map, {}) }

  # == Attributes ===========================================================
  it { is_expected.to have_attribute :connec_id }
  it { is_expected.to have_attribute :external_entity }
  it { is_expected.to have_attribute :external_id }
  it { is_expected.to have_attribute :name }
  it { is_expected.to have_attribute :message }

  # == Filters ==============================================================
  it { is_expected.to filter(:uid) }
  it { is_expected.to filter(:external_entity) }
end
