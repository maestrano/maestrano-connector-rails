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
        before(:each) do
          allow(Maestrano::Connector::Rails::SubEntityBase).to receive(:external?).and_return(true)
          allow(Maestrano::Connector::Rails::SubEntityBase).to receive(:entity_name).and_return('Name')
        end

        it 'returns the entity_name' do
          expect(subject.external_entity_name).to eql('Name')
        end
      end

      context 'when entity is not external' do
        before do
          allow(Maestrano::Connector::Rails::SubEntityBase).to receive(:external?).and_return(false)
        end
        it { expect{ subject.external_entity_name }.to raise_error('Forbidden call: cannot call external_entity_name for a connec entity') }
      end
    end

    describe 'connec_entity_name' do
      context 'when entity is not external' do
        before(:each) do
          allow(Maestrano::Connector::Rails::SubEntityBase).to receive(:external?).and_return(false)
          allow(Maestrano::Connector::Rails::SubEntityBase).to receive(:entity_name).and_return('Name')
        end

        it 'returns the entity_name' do
          expect(subject.connec_entity_name).to eql('Name')
        end
      end

      context 'when entity is external' do
        before do
          allow(Maestrano::Connector::Rails::SubEntityBase).to receive(:external?).and_return(true)
        end
        it { expect{ subject.connec_entity_name }.to raise_error('Forbidden call: cannot call connec_entity_name for an external entity') }
      end
    end

    describe 'names_hash' do
      let(:bool) { true }
      before do
        allow(Maestrano::Connector::Rails::SubEntityBase).to receive(:external?).and_return(bool)
        allow(Maestrano::Connector::Rails::SubEntityBase).to receive(:entity_name).and_return('Name')
      end

      context 'when external' do
        it { expect(subject.names_hash).to eql({external_entity: 'name'}) }
      end
      context 'when not external' do
        let(:bool) { false }
        it { expect(subject.names_hash).to eql({connec_entity: 'name'}) }
      end
    end

    it { expect(subject.mapper_classes).to eql({}) }
  end

  describe 'instance methods' do
    let!(:organization) { create(:organization, uid: 'cld-123') }
    let!(:connec_client) { Maestrano::Connec::Client[organization.tenant].new(organization.uid) }
    let!(:external_client) { Object.new }
    let(:opts) { {} }
    subject { Maestrano::Connector::Rails::SubEntityBase.new(organization, connec_client, external_client, opts) }

    describe 'map_to' do
      before do
        class AMapper
          extend HashMapper
        end
        allow(subject.class).to receive(:mapper_classes).and_return('Name' => AMapper)
      end

      describe 'failure' do
        it { expect{ subject.map_to('Not an entity', {}) }.to raise_error(RuntimeError) }
      end

      context 'when external' do
        before do
          allow(subject.class).to receive(:external?).and_return(true)
          allow(subject.class).to receive(:id_from_external_entity_hash).and_return('this id')
        end

        it 'calls the mapper denormalize' do
          expect(AMapper).to receive(:denormalize).with({}, subject.instance_values).and_return({})
          subject.map_to('Name', {})
        end

        it 'calls for reference folding' do
          refs = %w(organization_id person_id)
          allow(subject.class).to receive(:references).and_return({'Name' => refs})
          expect(Maestrano::Connector::Rails::ConnecHelper).to receive(:fold_references).with({id: 'this id'}, refs, organization)
          subject.map_to('Name', {})
        end

        it 'calls the creation_mapper_classes that delegates to the mapper_classes denormalize when passed true as a third argument' do
          expect(subject.class).to receive(:creation_mapper_classes).and_call_original
          expect(AMapper).to receive(:denormalize).with({}, subject.instance_values).and_return({})
          subject.map_to('Name', {}, nil)
        end

        context 'when no refs' do
          it 'calls for reference folding' do
            allow(subject.class).to receive(:references).and_return({})
            expect(Maestrano::Connector::Rails::ConnecHelper).to receive(:fold_references).with({id: 'this id'}, [], organization)
            subject.map_to('Name', {})
          end
        end

        context 'when connec_matching_fields' do
          before do
            expect(AMapper).to receive(:denormalize).and_return({opts: {a: 2}})
            allow(subject.class).to receive(:connec_matching_fields).and_return('matching_fields')
          end

          it 'adds the matching_fields in the entity opts' do
            expect(subject.map_to('Name', {})).to eql({id: [Maestrano::Connector::Rails::ConnecHelper.id_hash('this id', organization)], opts: {a: 2, matching_fields: 'matching_fields'}}.with_indifferent_access)
          end
        end
      end

      context 'when not external' do
        before do
          allow(subject.class).to receive(:external?).and_return(false)
        end

        it 'calls the mapper normalize' do
          expect(AMapper).to receive(:normalize).with({idmap: nil}, subject.instance_values).and_return({})
          subject.map_to('Name', {})
        end

        it 'calls the creation_mapper_classes that delegates to the mapper_classes normalize when passed true as a third argument' do
          expect(subject.class).to receive(:creation_mapper_classes).and_call_original
          expect(AMapper).to receive(:normalize).with({idmap: nil}, subject.instance_values).and_return({})
          subject.map_to('Name', {}, nil)
        end
      end
    end
  end
end
