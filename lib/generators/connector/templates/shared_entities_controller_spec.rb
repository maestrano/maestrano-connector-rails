require 'spec_helper'

describe SharedEntitiesController, :type => :controller do
  describe 'index' do
    subject { get :index }

    it { expect(subject).to be_success }

    context 'when user is admin' do
      let(:organization) {  create(:organization) }
      let(:idmap) { create(:idmap, organization: organization) }
      before {
        allow_any_instance_of(Maestrano::Connector::Rails::SessionHelper).to receive(:current_organization).and_return(organization)
        allow_any_instance_of(Maestrano::Connector::Rails::SessionHelper).to receive(:is_admin).and_return(true)
      }

      it 'assigns the idmaps' do
        subject
        expect(assigns(:idmaps)).to eq([idmap])
      end
    end
  end
end