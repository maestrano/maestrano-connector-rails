require 'spec_helper'

describe Maestrano::Connector::Rails::SubEntityBase do
  describe 'class methods' do
    subject { Maestrano::Connector::Rails::SubEntityBase }

    describe 'external?' do
      it { expect{ subject.external? }.to raise_error('Not implemented') }
    end

    describe 'entity_name' do
      it { expect{ subject.entity_name }.to raise_error('Not implemented') }
    end

    describe 'external_entity_name' do
      context 'when entity is external' do
        before(:each) {
          allow(Maestrano::Connector::Rails::SubEntityBase).to receive(:external?).and_return(true)
          allow(Maestrano::Connector::Rails::SubEntityBase).to receive(:entity_name).and_return('Name')
        }

        it 'returns the entity_name' do
          expect(subject.external_entity_name).to eql('Name')
        end
      end

      context 'when entity is not external' do
        before {
          allow(Maestrano::Connector::Rails::SubEntityBase).to receive(:external?).and_return(false)
        }
        it { expect{ subject.external_entity_name }.to raise_error('Forbidden call: cannot call external_entity_name for a connec entity') }
      end
    end

    describe 'connec_entity_name' do
      context 'when entity is not external' do
        before(:each) {
          allow(Maestrano::Connector::Rails::SubEntityBase).to receive(:external?).and_return(false)
          allow(Maestrano::Connector::Rails::SubEntityBase).to receive(:entity_name).and_return('Name')
        }

        it 'returns the entity_name' do
          expect(subject.connec_entity_name).to eql('Name')
        end
      end

      context 'when entity is external' do
        before {
          allow(Maestrano::Connector::Rails::SubEntityBase).to receive(:external?).and_return(true)
        }
        it { expect{ subject.connec_entity_name }.to raise_error('Forbidden call: cannot call connec_entity_name for an external entity') }
      end
    end

    describe 'names_hash' do
      let(:bool) { true }
      before {
        allow(Maestrano::Connector::Rails::SubEntityBase).to receive(:external?).and_return(bool)
        allow(Maestrano::Connector::Rails::SubEntityBase).to receive(:entity_name).and_return('Name')
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
        allow(Maestrano::Connector::Rails::SubEntityBase).to receive(:external?).and_return(bool)
        allow(Maestrano::Connector::Rails::SubEntityBase).to receive(:entity_name).and_return('Name')
        allow(Maestrano::Connector::Rails::SubEntityBase).to receive(:id_from_external_entity_hash).and_return('id')
        allow(Maestrano::Connector::Rails::SubEntityBase).to receive(:object_name_from_external_entity_hash).and_return('object name')
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
        allow(Maestrano::Connector::Rails::SubEntityBase).to receive(:external?).and_return(bool)
        allow(Maestrano::Connector::Rails::SubEntityBase).to receive(:entity_name).and_return('Name')
        allow(Maestrano::Connector::Rails::SubEntityBase).to receive(:object_name_from_connec_entity_hash).and_return('object name')
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

    it { expect(subject.mapper_classes).to eql({}) }
  end

  describe 'instance methods' do
    subject { Maestrano::Connector::Rails::SubEntityBase.new }

    describe 'map_to' do
      before {
        class AMapper
          extend HashMapper
        end
        allow(subject.class).to receive(:mapper_classes).and_return('Name' => AMapper)
      }

      context 'when external' do
        before {
          allow(subject.class).to receive(:external?).and_return(true)
        }

        it 'calls the mapper denormalize' do
          expect(AMapper).to receive(:denormalize).and_return({})
          subject.map_to('Name', {}, nil)
        end

        context 'with references' do
          let!(:organization) { create(:organization) }
          let!(:idmap) { create(:idmap, organization: organization) }
          before {
            clazz = Maestrano::Connector::Rails::Entity
            allow(clazz).to receive(:find_idmap).and_return(idmap)
            allow(subject.class).to receive(:references).and_return({'Name' => [{reference_class: clazz, connec_field: 'organization_id', external_field: 'contact_id'}]})
          }

          it 'returns the mapped entity with its references' do
            expect(subject.map_to('Name', {'contact_id' => idmap.external_id}, organization)).to eql({organization_id: idmap.connec_id})
          end
        end
      end
      context 'when not external' do
        before {
          allow(subject.class).to receive(:external?).and_return(false)
        }

        it 'calls the mapper normalize' do
          expect(AMapper).to receive(:normalize).and_return({})
          subject.map_to('Name', {}, nil)
        end

        context 'with references' do
          let!(:organization) { create(:organization) }
          let!(:idmap) { create(:idmap, organization: organization) }
          before {
            clazz = Maestrano::Connector::Rails::Entity
            allow(clazz).to receive(:find_idmap).and_return(idmap)
            allow(subject.class).to receive(:references).and_return({'Name' => [{reference_class: clazz, connec_field: 'organization_id', external_field: 'contact_id'}]})
          }

          it 'returns the mapped entity with its references' do
            expect(subject.map_to('Name', {'organization_id' => idmap.connec_id}, organization)).to eql({contact_id: idmap.external_id})
          end
        end
      end
    end
  end
end