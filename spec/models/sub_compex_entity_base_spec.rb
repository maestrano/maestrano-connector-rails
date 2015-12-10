require 'spec_helper'

describe Maestrano::Connector::Rails::SubComplexEntityBase do
  subject { Maestrano::Connector::Rails::SubComplexEntityBase.new }

  describe 'external?' do
    it { expect{ subject.external? }.to raise_error }
  end

  describe 'entity_name' do
    it { expect{ subject.entity_name }.to raise_error }
  end

  describe 'mapper_classes' do
    it { expect{ subject.mapper_classes }.to raise_error }
  end

  describe 'map_to' do
    it { expect{ subject.map_to('name', {}) }.to raise_error }
  end

  describe 'external_entity_name' do
    context 'when entity is external' do
      before(:each) {
        allow_any_instance_of(Maestrano::Connector::Rails::SubComplexEntityBase).to receive(:external?).and_return(true)
        allow_any_instance_of(Maestrano::Connector::Rails::SubComplexEntityBase).to receive(:entity_name).and_return('Name')
      }

      it 'returns the entity_name' do
        expect(subject.external_entity_name).to eql('Name')
      end
    end

    context 'when entity is not external' do
      it { expect{ subject.external_entity_name }.to raise_error }
    end
  end

  describe 'connec_entity_name' do
    context 'when entity is not external' do
      before(:each) {
        allow_any_instance_of(Maestrano::Connector::Rails::SubComplexEntityBase).to receive(:external?).and_return(false)
        allow_any_instance_of(Maestrano::Connector::Rails::SubComplexEntityBase).to receive(:entity_name).and_return('Name')
      }

      it 'returns the entity_name' do
        expect(subject.connec_entity_name).to eql('Name')
      end
    end

    context 'when entity is external' do
      it { expect{ subject.connec_entity_name }.to raise_error }
    end
  end
end