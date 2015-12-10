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
      expect(organization).to receive(:uid)
      expect(organization).to receive(:tenant)
      subject.log('info', organization, 'msg')
    end
  end

end