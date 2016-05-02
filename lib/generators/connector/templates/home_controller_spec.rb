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

      it 'updates organization synchronized_entities' do
        subject
        organization.reload
        expect(organization.synchronized_entities).to eq({'people' => true, 'item' => false})
      end

      it 'updates organization sync_enabled' do
        subject
        organization.reload
        expect(organization.sync_enabled).to eq true
      end

      context 'when removing all entities' do
        subject { put :update, id: organization.id, 'people' => false, 'item' => false }
        before { organization.update(sync_enabled: true) }

        it 'set sync_enabled to false' do
          subject
          organization.reload
          expect(organization.sync_enabled).to eq false
        end
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
        subject { post :synchronize, opts: {'opts' => 'some_opts'} }

        it 'calls perform_later with opts' do
          expect(Maestrano::Connector::Rails::SynchronizationJob).to receive(:perform_later).with(organization, {'opts' => 'some_opts', forced: true})
          subject
        end
      end

      context 'without opts' do
        subject { post :synchronize}

        it 'calls perform_later with empty opts hash' do
          expect(Maestrano::Connector::Rails::SynchronizationJob).to receive(:perform_later).with(organization, {forced: true})
          subject
        end
      end
    end
  end

  describe 'redirect_to_external' do
    subject { get :redirect_to_external }

    context 'otherwise' do
      it {expect(subject).to redirect_to('somewhere')}
    end
  end
end