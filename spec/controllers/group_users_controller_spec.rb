require 'spec_helper'

describe Maestrano::Account::GroupUsersController, type: :controller do
  routes { Maestrano::Connector::Rails::Engine.routes }

  describe "destroy" do
  	let!(:organization) { create(:organization, uid: 'cld-abc', tenant: 'abc') }
    let!(:user) { create(:user, tenant: 'abc', uid: 'usr-nnc') }
  	let(:params) { {tenant: organization.tenant, group_id: organization.uid, id: user.uid} }
  	subject { delete :destroy, params }

    before {
        controller.class.skip_before_filter :authenticate_maestrano!
        organization.add_member(user)
    }

  	it 'is successful' do
      subject
  		expect(response).to be_success
  	end

    it 'destroys the user_organization_rels' do
      expect{ subject }.to change{ Maestrano::Connector::Rails::UserOrganizationRel.count }.by(-1)
    end

    context 'with default tenant' do
      before {
        organization.update(tenant: 'default')
        user.update(tenant: 'default')
      }
      let(:params) { {group_id: organization.uid, id: user.uid} }

      it 'destroys the organization' do
        expect{ subject }.to change{ Maestrano::Connector::Rails::UserOrganizationRel.count }.by(-1)
      end
    end
  end

end