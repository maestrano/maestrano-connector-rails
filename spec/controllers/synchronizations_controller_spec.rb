require 'spec_helper'

describe Maestrano::SynchronizationsController, type: :controller do
  routes { Maestrano::Connector::Rails::Engine.routes }

  let(:uid) { 'cld-aaaa' }

  describe 'show' do
    subject { get :show, id: uid }


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

      context 'when organization is not found' do
        let!(:organization) { create(:organization, uid: 'cld-bbbb') }

        it 'is a 404' do
          subject
          expect(response.status).to eq(404)
        end
      end

      context 'when organization is found' do
        let!(:organization) { create(:organization, uid: uid) }

        it 'is a success' do
          subject
          expect(response.status).to eq(200)
        end

        context 'with no last sync' do
          it 'renders a partial json' do
            subject
            expect(JSON.parse(response.body)).to eql(
              JSON.parse({
                group_id: organization.uid,
                sync_enabled: organization.sync_enabled,
              }.to_json)
            )
          end
        end

        context 'with a last sync' do
          let!(:sync1) { create(:synchronization, organization: organization) }
          let!(:sync2) { create(:synchronization, organization: organization, message: 'msg') }

          it 'renders a full json' do
            subject
            expect(JSON.parse(response.body)).to eql(
              JSON.parse({
                group_id: organization.uid,
                sync_enabled: organization.sync_enabled,
                status: sync2.status,
                message: sync2.message,
                updated_at: sync2.updated_at   
              }.to_json)
            )
          end
        end
      end
    end
  end

  describe 'create' do
    let(:opts) { {'only_entities' => ['customer']} }
    subject { post :create, group_id: uid, opts: opts }


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

      context 'when organization is not found' do
        let!(:organization) { create(:organization, uid: 'cld-bbbb') }

        it 'is a 404' do
          subject
          expect(response.status).to eq(404)
        end
      end

      context 'when organization is found' do
        let!(:organization) { create(:organization, uid: uid) }

        it 'is a success' do
          subject
          expect(response.status).to eq(201)
        end

        it 'queues a sync' do
          expect(Maestrano::Connector::Rails::SynchronizationJob).to receive(:perform_later).with(organization, opts)
          subject
        end
      end
    end
  end

  describe 'destroy' do
    subject { delete :destroy, id: uid }


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

      context 'when organization is not found' do
        let!(:organization) { create(:organization, uid: 'cld-bbbb') }

        it 'is a 404' do
          subject
          expect(response.status).to eq(404)
        end
      end

      context 'when organization is found' do
        let!(:organization) { create(:organization, uid: uid, sync_enabled: true) }

        it 'is a success' do
          subject
          expect(response.status).to eq(200)
        end

        it 'disable the organizatio syncs' do
          subject
          expect(organization.reload.sync_enabled).to be false
        end
      end
    end
  end
end
