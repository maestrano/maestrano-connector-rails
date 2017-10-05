require 'spec_helper'

describe Maestrano::Account::GroupsController, type: :controller do
  routes { Maestrano::Connector::Rails::Engine.routes }

  describe "destroy" do
  	let!(:organization) { create(:organization, uid: 'cld-abc', tenant: 'abc') }
  	let(:params) { {tenant: organization.tenant, id: organization.uid} }
  	subject { delete :destroy, params }

    before { controller.class.skip_before_filter :authenticate_maestrano! }

  	it 'is successful' do
      subject
  		expect(response).to be_success
      expect(response.code).to eq '200'
  	end

    it 'destroys the organization' do
      expect{ subject }.to change{ Maestrano::Connector::Rails::Organization.count }.by(-1)
    end

    context 'when organization is not found' do
      before { organization.delete}

      it 'returns not modified' do
        expect{ subject }.to change{ Maestrano::Connector::Rails::Organization.count }.by(0)
        expect(response.code).to eq '204'
      end
    end

    context 'with default tenant' do
      before { organization.update(tenant: 'default') }
      let(:params) { {id: organization.uid} }

      it 'destroys the organization' do
        expect{ subject }.to change{ Maestrano::Connector::Rails::Organization.count }.by(-1)
      end
    end
  end

end
