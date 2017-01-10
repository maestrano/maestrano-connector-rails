require 'spec_helper'

describe Maestrano::ConnecController, type: :controller do
  routes { Maestrano::Connector::Rails::Engine.routes }

  describe 'notifications' do
    let(:notifications) { {} }
    let(:group_id) { 'cld_333' }
    let(:params) { {tenant: 'default'}.merge(notifications) }
    let(:entity) { {group_id: group_id, last_name: 'Georges', first_name: 'Teddy'} }
    subject { post :notifications, params }

    context 'without authentication' do
      before {
        controller.class.before_filter :authenticate_maestrano!
      }

      it 'respond with unauthorized' do
        subject
        expect(response.status).to eq(401)
      end
    end

    context 'with authentication' do
      before {
        controller.class.skip_before_filter :authenticate_maestrano!
      }

      it 'is a success' do
        subject
        expect(response.status).to eq(200)
      end

      context 'with an unexpected error' do
        let(:notifications) { {'people' => [entity]} }
        it 'does nothing' do
          allow(controller).to receive(:find_entity_class).and_raise('Unexpected error')
          expect(Maestrano::Connector::Rails::External).to_not receive(:get_client)
          subject
        end
      end

      context "with an unknown entity" do
        let(:notifications) { {'people' => [entity]} }
        before {
          allow(Maestrano::Connector::Rails::External).to receive(:entities_list).and_return(%w())
        }

        it 'does nothing' do
          expect(Maestrano::Connector::Rails::External).to_not receive(:get_client)
          subject
        end
      end

      context "with a known complex entity" do
        let(:notifications) { {'leads' => [entity]} }

        before {
          allow(Maestrano::Connector::Rails::External).to receive(:entities_list).and_return(%w(contact_and_lead))
          class Entities::ContactAndLead < Maestrano::Connector::Rails::ComplexEntity
            def self.connec_entities_names
              %w(Lead)
            end
          end
          module Entities::SubEntities end;
          class Entities::SubEntities::Lead < Maestrano::Connector::Rails::SubEntityBase
          end
        }

        it 'looks for an organization' do
          expect(Maestrano::Connector::Rails::Organization).to receive(:find_by).with(uid: group_id, tenant: 'default')
          subject
        end

        context 'when syncing' do
          before {
            allow(Entities::ContactAndLead).to receive(:external_entities_names).and_return(%w())
          }
          let!(:organization) { create(:organization, uid: group_id, oauth_uid: 'lala', sync_enabled: true, synchronized_entities: {contact_and_lead: true}) }

          it 'process the data and push them' do
            expect_any_instance_of(Entities::ContactAndLead).to receive(:before_sync)
            expect_any_instance_of(Entities::ContactAndLead).to receive(:filter_connec_entities).with({"Lead"=>[entity]}).and_return({"Lead"=>[entity]})
            expect_any_instance_of(Entities::ContactAndLead).to receive(:consolidate_and_map_data).with({"Lead"=>[entity]}, {}).and_return({})
            expect_any_instance_of(Entities::ContactAndLead).to receive(:push_entities_to_external)
            expect_any_instance_of(Entities::ContactAndLead).to receive(:after_sync)
            begin
            subject
          rescue => e
            puts e
          end
          end
        end
      end

      context "with a known non complex entity" do
        let(:notifications) { {'people' => [entity]} }

        before {
          allow(Maestrano::Connector::Rails::External).to receive(:entities_list).and_return(%w(person))
          class Entities::Person < Maestrano::Connector::Rails::Entity
            def self.connec_entity_name
              'People'
            end
          end
        }

        it 'looks for an organization' do
          expect(Maestrano::Connector::Rails::Organization).to receive(:find_by).with(uid: group_id, tenant: 'default')
          subject
        end

        context 'with an invalid organization' do
          context 'with no organization' do
            it 'does nothing' do
              expect(Maestrano::Connector::Rails::External).to_not receive(:get_client)
              subject
            end
          end

          context 'with an organization with no oauth' do
            let!(:organization) { create(:organization, uid: group_id, oauth_uid: nil) }

            it 'does nothing' do
              expect(Maestrano::Connector::Rails::External).to_not receive(:get_client).with(organization)
              subject
            end
          end
        end

        context 'with a valid organization' do
          context 'with sync disabled' do
            let!(:organization) { create(:organization, uid: group_id, oauth_uid: 'lala', sync_enabled: false, synchronized_entities: {person: true}) }

            it 'does nothing' do
              expect(Maestrano::Connector::Rails::External).to_not receive(:get_client).with(organization)
              subject
            end
          end

          context 'with sync disabled for this entity' do
            let!(:organization) { create(:organization, uid: group_id, oauth_uid: 'lala', sync_enabled: true, synchronized_entities: {person: false}) }

            it 'does nothing' do
              expect(Maestrano::Connector::Rails::External).to_not receive(:get_client).with(organization)
              subject
            end
          end

          context "when syncing" do
            let!(:organization) { create(:organization, uid: group_id, oauth_uid: 'lala', sync_enabled: true, synchronized_entities: {person: true}) }

            it 'process the data and push them' do
              expect_any_instance_of(Entities::Person).to receive(:before_sync)
              expect_any_instance_of(Entities::Person).to receive(:filter_connec_entities).and_return([entity])
              expect_any_instance_of(Entities::Person).to receive(:consolidate_and_map_data).with([entity], []).and_return({})
              expect_any_instance_of(Entities::Person).to receive(:push_entities_to_external)
              expect_any_instance_of(Entities::Person).to receive(:after_sync)
              subject
            end

            context 'with different entity name case and singular' do
              let(:notifications) { {'Person' => [entity]} }

              it 'process the data and push them' do
                expect_any_instance_of(Entities::Person).to receive(:before_sync)
                expect_any_instance_of(Entities::Person).to receive(:filter_connec_entities).and_return([entity])
                expect_any_instance_of(Entities::Person).to receive(:consolidate_and_map_data).with([entity], []).and_return({})
                expect_any_instance_of(Entities::Person).to receive(:push_entities_to_external)
                expect_any_instance_of(Entities::Person).to receive(:after_sync)
                subject
              end
            end
          end
        end
      end
    end
  end
end
