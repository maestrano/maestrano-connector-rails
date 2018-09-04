require 'spec_helper'

describe Maestrano::Connector::Rails::Services::DataSanitizer do
  let(:mock_profile) { YAML.load_file('spec/dummy/config/profiles/test_sanitizer_profile.yml') }

  describe 'described_class#sanitize' do
    subject(:sanitized_data) { sanitizer.sanitize('employee', employee_data) }

    let(:sanitizer) { Maestrano::Connector::Rails::Services::DataSanitizer.new('test_sanitizer_profile.yml') }

    before do
      allow(File).to receive(:file?).and_return(true)
    end

    it 'loads sanitizer profile' do
      expect(sanitizer.instance_variable_get(:@profile)).to eq(mock_profile)
    end

    context 'when data is a hash' do
      let(:employee_data) do
        {
          "first_name" => "Jon",
          "last_name" => "Doe",
          "full_name" => "Jon Doe",
          "email" => {
            "address" => "test@example.com"
          }
        }
      end

      it 'sanitizes the hash based on the profile' do
        expect(sanitized_data['full_name']).to be_nil
        expect(sanitized_data['first_name']).not_to eq(employee_data['first_name'])
        expect(sanitized_data['last_name']).not_to eq(employee_data['last_name'])
        expect(decrypt_hashed_value(sanitized_data['first_name'])).to eq(employee_data['first_name'])
        expect(decrypt_hashed_value(sanitized_data['last_name'])).to eq(employee_data['last_name'])
        expect(decrypt_hashed_value(sanitized_data['email']['address'])).to eq(employee_data['email']['address'])
      end
    end

    context 'when data is an array of hashes' do
      
    end

  end

  private

   def decrypt_hashed_value(hashed_value)
    cipher = OpenSSL::Cipher.new('AES-128-ECB').decrypt
    cipher.key = Rails.application.secrets.secret_key_base[0..15]
    cipher.update(Base64.decode64(hashed_value)) + cipher.final
  end
end
