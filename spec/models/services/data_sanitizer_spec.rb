require 'spec_helper'

describe Maestrano::Connector::Rails::Services::DataSanitizer do
  let(:mock_profile) { YAML.load_file('spec/dummy/config/profiles/test_sanitizer_profile.yml') }

  describe 'described_class#sanitize' do
    let(:sanitizer) { Maestrano::Connector::Rails::Services::DataSanitizer.new('test_sanitizer_profile.yml') }

    it 'loads sanitizer profile' do
      expect(sanitizer.instance_variable_get(:@profile)).to eq(mock_profile)
    end

    context 'when data is a hash' do
      subject(:sanitized_data) { sanitizer.sanitize('employee', employee_data) }

      let(:sanitizer) { Maestrano::Connector::Rails::Services::DataSanitizer.new('test_sanitizer_profile.yml') }

      let(:employee_data) do
        {
          'first_name' => 'Jon',
          'last_name' => 'Doe',
          'full_name' => 'Jon Doe',
          'email' => {
            'address' => 'test@example.com'
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
      subject(:sanitized_data) { sanitizer.sanitize('employee', employee_data) }

      let(:sanitizer) { Maestrano::Connector::Rails::Services::DataSanitizer.new('test_sanitizer_profile.yml') }

      let(:employee_data) do
        [
          {
            'first_name' => 'Adam',
            'last_name' => 'Abdelaziz',
            'full_name' => 'Adam Abdelaziz',
            'email' => {
              'address' => 'test@example.com'
            }
          },
          {
            'first_name' => 'Jane',
            'last_name' => 'Doe',
            'full_name' => 'Jane Doe',
            'email' => {
              'address' => 'test1@example.com'
            }
          }
        ]
      end

      it 'sanitizes the first hash in the array based on the profile' do
        expect(sanitized_data[0]['full_name']).to be_nil
        expect(sanitized_data[0]['first_name']).not_to eq(employee_data[0]['first_name'])
        expect(sanitized_data[0]['last_name']).not_to eq(employee_data[0]['last_name'])
        expect(decrypt_hashed_value(sanitized_data[0]['first_name'])).to eq(employee_data[0]['first_name'])
        expect(decrypt_hashed_value(sanitized_data[0]['last_name'])).to eq(employee_data[0]['last_name'])
        expect(decrypt_hashed_value(sanitized_data[0]['email']['address'])).to eq(employee_data[0]['email']['address'])
      end

      it 'sanitizes other hashes in the array based on profile' do
        expect(sanitized_data[0]['full_name']).to be_nil
        expect(sanitized_data[0]['first_name']).not_to eq(employee_data[0]['first_name'])
        expect(sanitized_data[0]['last_name']).not_to eq(employee_data[0]['last_name'])
        expect(decrypt_hashed_value(sanitized_data[0]['first_name'])).to eq(employee_data[0]['first_name'])
        expect(decrypt_hashed_value(sanitized_data[0]['last_name'])).to eq(employee_data[0]['last_name'])
        expect(decrypt_hashed_value(sanitized_data[0]['email']['address'])).to eq(employee_data[0]['email']['address'])
      end
    end

    context 'when data is more deeply nested' do
      subject(:sanitized_data) { sanitizer.sanitize('employee', employee_data) }

      let(:sanitizer) { Maestrano::Connector::Rails::Services::DataSanitizer.new('test_sanitizer_profile.yml') }

      let(:first_friends) do
        [
          {
            'address' => '404 w 5th ave',
            'name' => {
              'first_name' => 'Isaac',
              'last_name' => 'Seessel',
              'friends'=> second_friends
            }
          },
          {
            'address' => '123 w 2nd street',
            'name' => {
              'first_name' => 'Paul',
              'last_name' => 'Parker'
            }
          }
        ]
      end

      let(:second_friends) do
        [
          {
            'address' => '101 w 2nd st',
            'name' => {
              'first_name' => 'Celine',
              'last_name' => 'Castleman'
            }
          },
          {
            'address' => '202 w 3rd st.',
            'name' => {
              'first_name' => 'Alex',
              'last_name' => 'Thomas'
            }
          }
        ]
      end

      let(:employee_data) do
        [
          {
            'first_name' => 'Jon',
            'last_name' => 'Doe',
            'full_name' => 'Jon Doe',
            'email' => {
              'address' => 'test@example.com'
            },
            'friends' => first_friends
          },
          {
            'first_name' => 'Jane',
            'last_name' => 'Doe',
            'full_name' => 'Jane Doe',
            'email' => {
              'address' => 'test1@example.com'
            },
            'friends' => second_friends
          }
        ]
      end

      it 'sanitizes the first hash in the array based on the profile' do
        expect(sanitized_data[0]['full_name']).to be_nil
        expect(sanitized_data[0]['first_name']).not_to eq(employee_data[0]['first_name'])
        expect(sanitized_data[0]['last_name']).not_to eq(employee_data[0]['last_name'])
        expect(decrypt_hashed_value(sanitized_data[0]['first_name'])).to eq(employee_data[0]['first_name'])
        expect(decrypt_hashed_value(sanitized_data[0]['last_name'])).to eq(employee_data[0]['last_name'])
        expect(decrypt_hashed_value(sanitized_data[0]['email']['address'])).to eq(employee_data[0]['email']['address'])
      end

      it 'sanitizes other hashes in the array based on profile' do
        expect(sanitized_data[0]['full_name']).to be_nil
        expect(sanitized_data[0]['first_name']).not_to eq(employee_data[0]['first_name'])
        expect(sanitized_data[0]['last_name']).not_to eq(employee_data[0]['last_name'])
        expect(decrypt_hashed_value(sanitized_data[0]['first_name'])).to eq(employee_data[0]['first_name'])
        expect(decrypt_hashed_value(sanitized_data[0]['last_name'])).to eq(employee_data[0]['last_name'])
        expect(decrypt_hashed_value(sanitized_data[0]['email']['address'])).to eq(employee_data[0]['email']['address'])
      end

      it 'sanitizes the nested array' do
        sanitized_address = sanitized_data[0]['friends'][0]['address']
        address = employee_data[0]['friends'][0]['address']

        expect(sanitized_address).not_to eq(address)
        expect(decrypt_hashed_value(sanitized_address)).to eq(address)

        expect(sanitized_data[0]['friends'][0]['name']['first_name']).to be_nil
        expect(sanitized_data[0]['friends'][1]['name']['first_name']).to be_nil
        expect(sanitized_data[1]['friends'][0]['name']['first_name']).to be_nil
        expect(sanitized_data[1]['friends'][1]['name']['first_name']).to be_nil

        sanitized_first_name = sanitized_data[1]['friends'][1]['name']['last_name']
        first_name = employee_data[1]['friends'][1]['name']['last_name']

        expect(sanitized_first_name).not_to eq(first_name)
        expect(decrypt_hashed_value(sanitized_first_name)).to eq(first_name)
      end
    end

    context 'when profile not given' do
      subject(:sanitized_data) { sanitizer.sanitize('employee', employee_data) }

      let(:sanitizer) { Maestrano::Connector::Rails::Services::DataSanitizer.new('fake_profile.yml') }

      let(:employee_data) do
        {
          'first_name' => 'Jon',
          'last_name' => 'Doe',
          'full_name' => 'Jon Doe',
          'email' => {
            'address' => 'test@example.com'
          }
        }
      end

      it 'returns the original object' do
        expect(sanitized_data).to eq(employee_data)
      end
    end
  end

  private

   def decrypt_hashed_value(hashed_value)
    cipher = OpenSSL::Cipher.new('AES-128-ECB').decrypt
    cipher.key = Rails.application.secrets.secret_key_base[0..15]
    cipher.update(Base64.decode64(hashed_value)) + cipher.final
  end
end
