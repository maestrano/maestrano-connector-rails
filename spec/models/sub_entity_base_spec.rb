require 'spec_helper'

describe Maestrano::Connector::Rails::SubEntityBase do
  subject { Maestrano::Connector::Rails::SubEntityBase.new }

  describe 'external?' do
    it { expect{ subject.external? }.to raise_error('Not implemented') }
  end

  describe 'entity_name' do
    it { expect{ subject.entity_name }.to raise_error('Not implemented') }
  end

  describe 'map_to' do
    it { expect{ subject.map_to('name', {}, nil) }.to raise_error('Not implemented') }
  end

  describe 'external_entity_name' do
    context 'when entity is external' do
      before(:each) {
        allow_any_instance_of(Maestrano::Connector::Rails::SubEntityBase).to receive(:external?).and_return(true)
        allow_any_instance_of(Maestrano::Connector::Rails::SubEntityBase).to receive(:entity_name).and_return('Name')
      }

      it 'returns the entity_name' do
        expect(subject.external_entity_name).to eql('Name')
      end
    end

    context 'when entity is not external' do
      before {
        allow_any_instance_of(Maestrano::Connector::Rails::SubEntityBase).to receive(:external?).and_return(false)
      }
      it { expect{ subject.external_entity_name }.to raise_error('Forbidden call: cannot call external_entity_name for a connec entity') }
    end
  end

  describe 'connec_entity_name' do
    context 'when entity is not external' do
      before(:each) {
        allow_any_instance_of(Maestrano::Connector::Rails::SubEntityBase).to receive(:external?).and_return(false)
        allow_any_instance_of(Maestrano::Connector::Rails::SubEntityBase).to receive(:entity_name).and_return('Name')
      }

      it 'returns the entity_name' do
        expect(subject.connec_entity_name).to eql('Name')
      end
    end

    context 'when entity is external' do
      before {
        allow_any_instance_of(Maestrano::Connector::Rails::SubEntityBase).to receive(:external?).and_return(true)
      }
      it { expect{ subject.connec_entity_name }.to raise_error('Forbidden call: cannot call connec_entity_name for an external entity') }
    end
  end

  describe 'names_hash' do
    let(:bool) { true }
    before {
      allow_any_instance_of(Maestrano::Connector::Rails::SubEntityBase).to receive(:external?).and_return(bool)
      allow_any_instance_of(Maestrano::Connector::Rails::SubEntityBase).to receive(:entity_name).and_return('Name')
    }

    context 'when external' do
      it { expect(subject.names_hash).to eql({external_entity: 'name'}) }
    end
    context 'when not external' do
      let(:bool) { false }
      it { expect(subject.names_hash).to eql({connec_entity: 'name'}) }
    end
  end

  describe 'create_idmap_from_external_entity' do
    let(:organization) { create(:organization) }
    let(:bool) { true }
    before {
      allow_any_instance_of(Maestrano::Connector::Rails::SubEntityBase).to receive(:external?).and_return(bool)
      allow_any_instance_of(Maestrano::Connector::Rails::SubEntityBase).to receive(:entity_name).and_return('Name')
      allow_any_instance_of(Maestrano::Connector::Rails::SubEntityBase).to receive(:get_id_from_external_entity_hash).and_return('id')
      allow_any_instance_of(Maestrano::Connector::Rails::SubEntityBase).to receive(:object_name_from_external_entity_hash).and_return('object name')
    }

    context 'when external' do
      it {
        expect(Maestrano::Connector::Rails::IdMap).to receive(:create).with({:external_entity=>"name", :external_id=>"id", :name=>"object name", :connec_entity=>"lala", :organization_id=>1})
        subject.create_idmap_from_external_entity({}, 'lala', organization)
      }
    end
    context 'when not external' do
      let(:bool) { false }
      it { expect{ subject.create_idmap_from_external_entity({}, '', organization) }.to raise_error('Forbidden call: cannot call create_idmap_from_external_entity for a connec entity') }
    end
  end

  describe 'create_idmap_from_connec_entity' do
    let(:organization) { create(:organization) }
    let(:bool) { true }
    before {
      allow_any_instance_of(Maestrano::Connector::Rails::SubEntityBase).to receive(:external?).and_return(bool)
      allow_any_instance_of(Maestrano::Connector::Rails::SubEntityBase).to receive(:entity_name).and_return('Name')
      allow_any_instance_of(Maestrano::Connector::Rails::SubEntityBase).to receive(:object_name_from_connec_entity_hash).and_return('object name')
    }

    context 'when external' do
      it { expect{ subject.create_idmap_from_connec_entity({}, '', organization) }.to raise_error('Forbidden call: cannot call create_idmap_from_connec_entity for an external entity') }
    end
    context 'when not external' do
      let(:bool) { false }
      it {
        expect(Maestrano::Connector::Rails::IdMap).to receive(:create).with({:connec_entity=>"name", :connec_id=>"lili", :name=>"object name", :external_entity=>"lala", :organization_id=>1})
        subject.create_idmap_from_connec_entity({'id' => 'lili'}, 'lala', organization)
      }
    end
  end
end