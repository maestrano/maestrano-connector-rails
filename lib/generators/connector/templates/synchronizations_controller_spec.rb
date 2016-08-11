require 'spec_helper'

describe SynchronizationsController, type: :controller do
  describe 'index' do
    subject { get :index }

    it { expect(subject).to be_success }

    context 'when user is logged in' do
      let(:organization) {  create(:organization) }
      let(:synchronization) { create(:synchronization, organization: organization) }
      before do
        allow_any_instance_of(Maestrano::Connector::Rails::SessionHelper).to receive(:current_organization).and_return(organization)
      end

      it 'assigns the synchronizations' do
        subject
        expect(assigns(:synchronizations)).to eq([synchronization])
      end
    end
  end
end
