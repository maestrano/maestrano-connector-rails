require 'spec_helper'

describe HomeController, :type => :controller do
  let(:back_path) { home_index_path }
  before(:each) do
    request.env["HTTP_REFERER"] = back_path
  end

  describe 'index' do
    subject { get :index }

    it { expect(subject).to be_success }
  end

  describe 'update' do
    let(:organization) { create(:organization, synchronized_entities: {'people' => false, 'item' => true}) }
    subject { put :update, id: organization.id, 'people' => true, 'item' => false, 'lala' => true }


    context 'when user is not admin' do
      before {
        allow_any_instance_of(Maestrano::Connector::Rails::SessionHelper).to receive(:is_admin?).and_return(false)
      }

      it { expect(subject).to redirect_to back_path }
    end

    context 'when user is admin' do
      before {
        allow_any_instance_of(Maestrano::Connector::Rails::SessionHelper).to receive(:is_admin?).and_return(true)
      }

      it { expect(subject).to redirect_to back_path }

      it 'updates organization' do
        subject
        organization.reload
        expect(organization.synchronized_entities).to eq({'people' => true, 'item' => false})
      end
    end
  end

  describe 'synchronize' do
    subject { post :synchronize }
    let(:organization) { create(:organization) }
    before {
      allow_any_instance_of(Maestrano::Connector::Rails::SessionHelper).to receive(:current_organization).and_return(organization)
    }

    context 'when user is not admin' do
      before {
        allow_any_instance_of(Maestrano::Connector::Rails::SessionHelper).to receive(:is_admin).and_return(false)
      }

      it { expect(subject).to redirect_to back_path }

      it 'does nothing' do
        expect(Maestrano::Connector::Rails::SynchronizationJob).to_not receive(:perform_later)
        subject
      end
    end

    context 'when user is admin' do
      before {
        allow_any_instance_of(Maestrano::Connector::Rails::SessionHelper).to receive(:is_admin).and_return(true)
      }

      it { expect(subject).to redirect_to back_path }

      context 'with opts' do
        subject { post :synchronize, opts: 'opts' }

        it 'calls perform_later with opts' do
          expect(Maestrano::Connector::Rails::SynchronizationJob).to receive(:perform_later).with(organization, 'opts')
          subject
        end
      end

      context 'without opts' do
        subject { post :synchronize}

        it 'calls perform_later with empty opts hash' do
          expect(Maestrano::Connector::Rails::SynchronizationJob).to receive(:perform_later).with(organization, {})
          subject
        end
      end
    end

    describe 'toggle_sync' do
      subject { put :toggle_sync }
      let(:organization) { create(:organization, sync_enabled: true) }
      before {
        allow_any_instance_of(Maestrano::Connector::Rails::SessionHelper).to receive(:current_organization).and_return(organization)
      }

      context 'when user is not an admin' do
        before {
          allow_any_instance_of(Maestrano::Connector::Rails::SessionHelper).to receive(:is_admin).and_return(false)
        }
        it { expect(subject).to redirect_to back_path }

        it 'does nothing' do
          expect{ subject }.to_not change{ organization.sync_enabled }
        end
      end

      context 'when user is admin' do
        before {
          allow_any_instance_of(Maestrano::Connector::Rails::SessionHelper).to receive(:is_admin).and_return(true)
        }
        it { expect(subject).to redirect_to back_path }

        it 'change sync_enabled from true to false' do
          expect{ subject }.to change{ organization.sync_enabled }.from(true).to(false)
        end

        it 'change sync_enabled from false to true' do
          organization.update(sync_enabled: false)
          expect{ subject }.to change{ organization.sync_enabled }.from(false).to(true)
        end
      end
    end
  end
end