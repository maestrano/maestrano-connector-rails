require 'spec_helper'

describe Maestrano::Connector::Rails::EntityHelper do

  subject  { Maestrano::Connector::Rails::EntityHelper}

  let!(:organization) { create(:organization, uid: 'cld-123') }
  let!(:connec_client) { Maestrano::Connec::Client[organization.tenant].new(organization.uid) }
  let!(:external_client) { Object.new }
  let(:opts) { {} }

  before do
    allow(Maestrano::Connector::Rails::ComplexEntity).to receive(:external_entities_names).and_return(%w(Avoid NotImplementedError))
    allow(Maestrano::Connector::Rails::ComplexEntity).to receive(:connec_entities_names).and_return(%w(Avoid NotImplementedError))
  end

  describe '#self.snake_name' do

    context 'when regular Entity' do
      let!(:entity) { Maestrano::Connector::Rails::Entity.new(organization, connec_client, external_client, opts) }

      it 'Returns the name symbolized name of the entity' do

        expect(subject.snake_name(entity)).to eq :entity
      end
    end

    context 'when SubEntity' do

      let!(:complex_entity_test) do
        class Entities::ComplexEntityTest < Maestrano::Connector::Rails::ComplexEntity

          def self.external_entities_names
            {The_entity_name: 'TheEntityName', tested_entity_name: 'Test' }
          end

          def self.connec_entities_names
            %w(ToAvoid NotImplementedError)
          end
        end

        Entities::ComplexEntityTest.new(organization, connec_client, external_client, opts)
      end

      let(:sub_entity) do
        class Entities::Test < Maestrano::Connector::Rails::SubEntityBase
        end

        Entities::Test.new(organization, connec_client, external_client, opts)
      end

      it "looks into the 'formatted entities names' to find the complex entity name" do

        expect(subject.snake_name(sub_entity)).to eq :complex_entity_test
      end
    end

    context 'When name is composite' do

      let!(:complex_entity_composite) do
        class Entities::ComplexEntityComposite < Maestrano::Connector::Rails::ComplexEntity

          def self.external_entities_names
            {The_entity_name: 'TheEntityName', Tested_entity_name: 'The Tested Class' }
          end

          def self.connec_entities_names
            %w(ToAvoid NotImplementedError)
          end
        end

        Entities::ComplexEntityComposite.new(organization, connec_client, external_client, opts)
      end

      let(:sub_entity_composite) do
        class Entities::TheTestedClass < Maestrano::Connector::Rails::SubEntityBase
        end

        Entities::TheTestedClass.new(organization, connec_client, external_client, opts)
      end

      it { expect(subject.snake_name(sub_entity_composite)).to eq :complex_entity_composite}
    end
  end

  describe '#self.camel_case_format' do

    let(:entities_names) { ['Tested Class', 'tested class', 'Tested_class', 'tested_CLASS']}

    it 'formats the given array of strings to camel case' do

      expect(subject.camel_case_format(entities_names).uniq).to eq ['TestedClass']
    end
  end
end
