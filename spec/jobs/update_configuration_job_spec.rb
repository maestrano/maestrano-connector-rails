require 'spec_helper'

describe Maestrano::Connector::Rails::UpdateConfigurationJob do
  subject { described_class.perform_now }

  describe 'perform' do
    it 'reloads the configuration' do
      expect(Maestrano).to receive(:reset!)
      expect(Maestrano).to receive(:auto_configure)

      subject

      expect(Maestrano.configs).to be_any
    end
  end
end
