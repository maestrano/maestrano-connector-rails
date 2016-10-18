require 'spec_helper'

describe Maestrano::Connector::Rails::ConnectorLogger do
  subject { Maestrano::Connector::Rails::ConnectorLogger }

  describe 'self.log' do
    let(:organization) { create(:organization) }

    it 'calls rails.logger' do
      expect(Rails.logger).to receive(:info)
      subject.log('info', organization, 'msg')
    end

    it 'includes the organization uid and tenant' do
      expect(Rails.logger).to receive(:info).with("uid=\"#{organization.uid}\", org_uid=\"#{organization.org_uid}\", tenant=\"#{organization.tenant}\", message=\"msg\"")

      subject.log('info', organization, 'msg')
    end

    it 'includes extra params' do
      expect(Rails.logger).to receive(:info).with("uid=\"#{organization.uid}\", org_uid=\"#{organization.org_uid}\", tenant=\"#{organization.tenant}\", foo=\"bar\", message=\"msg\"")

      subject.log('info', organization, 'msg', foo: :bar)
    end
  end
end
