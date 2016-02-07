require 'spec_helper'

describe Maestrano::ConnecController, type: :controller do
  routes { Maestrano::Connector::Rails::Engine.routes }

  describe 'notifications' do
    let(:notif) { {} }
    let(:group_id) { 'cld_333' }
    let(:entity) { {group_id: group_id, last_name: 'Georges', first_name: 'Teddy'} }
    subject { post :notifications, tenant: 'default', notification: notif }

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

      context "with an unknown entity" do
        let(:notif) { {people: [entity]} }
        before {
          allow(Maestrano::Connector::Rails::Entity).to receive(:entities_list).and_return(%w())
        }

        it 'logs a warning' do
          expect(Rails.logger).to receive(:warn).with('Received notification from Connec! for unknow entity: people')
          subject
        end
      end

      context "with a known complex entity" do
        let(:notif) { {lead: [entity]} }

        before {
          allow(Maestrano::Connector::Rails::Entity).to receive(:entities_list).and_return(%w(contact_and_lead))
          class Entities::ContactAndLead < Maestrano::Connector::Rails::ComplexEntity
            def connec_entities_names
              %w(lead)
            end
          end
          class Entities::SubEntities::Lead < Maestrano::Connector::Rails::SubEntityBase
          end
        }

        it 'looks for an organization' do
          expect(Maestrano::Connector::Rails::Organization).to receive(:find_by).with(uid: group_id, tenant: 'default')
          subject
        end

        context 'when syncing' do
          before {
            allow_any_instance_of(Entities::ContactAndLead).to receive(:external_entities_names).and_return(%w())
          }
          let!(:organization) { create(:organization, uid: group_id, oauth_uid: 'lala', sync_enabled: true, synchronized_entities: {contact_and_lead: true}) }

          it 'process the data and push them' do
            expect_any_instance_of(Entities::ContactAndLead).to receive(:consolidate_and_map_data).with({"lead"=>[entity]}, {}, organization, {})
            expect_any_instance_of(Entities::ContactAndLead).to receive(:push_entities_to_external)
            subject
          end
        end
      end

      context "with a known non complex entity" do
        let(:notif) { {people: [entity]} }

        before {
          allow(Maestrano::Connector::Rails::Entity).to receive(:entities_list).and_return(%w(person))
          class Entities::Person < Maestrano::Connector::Rails::Entity
          end
        }

        it 'looks for an organization' do
          expect(Maestrano::Connector::Rails::Organization).to receive(:find_by).with(uid: group_id, tenant: 'default')
          subject
        end

        context 'with an invalid organization' do
          context 'with no organization' do
            it 'logs a warning' do
              expect(Rails.logger).to receive(:warn).with("Received notification from Connec! for unknown group or group without oauth: #{group_id} (tenant: default)")
              subject
            end
          end

          context 'with an organization with no oauth' do
            let!(:organization) { create(:organization, uid: group_id, oauth_uid: nil) }

            it 'logs a warning' do
              expect(Rails.logger).to receive(:warn).with("Received notification from Connec! for unknown group or group without oauth: #{group_id} (tenant: default)")
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
              expect_any_instance_of(Entities::Person).to receive(:consolidate_and_map_data).with([entity], [], organization, {})
              expect_any_instance_of(Entities::Person).to receive(:push_entities_to_external)
              subject
            end
          end
        end

      end
    end
  end
end
