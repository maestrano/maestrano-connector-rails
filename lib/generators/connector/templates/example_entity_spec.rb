# TODO
# This file is provided as an example and should be removed
# require 'spec_helper'

# describe Entities::ExampleEntity do

#   describe 'class methods' do
#     subject { Entities::ExampleEntity }

#     it { expect(subject.connec_entity_name).to eql('ExampleEntity') }
#     it { expect(subject.external_entity_name).to eql('Contact') }
#     it { expect(subject.object_name_from_connec_entity_hash({'first_name' => 'A', 'last_name' => 'contact'})).to eql('A contact') }
#     it { expect(subject.object_name_from_external_entity_hash({'FirstName' => 'A', 'LastName' => 'contact'})).to eql('A contact') }
#   end

#   describe 'instance methods' do
#     let(:organization) { create(:organization) }
#     let(:connec_client) { Maestrano::Connector::Rails::ConnecHelper.get_client(organization) }
#     let(:external_client) { Maestrano::Connector::Rails::External.get_client(organization) }
#     let(:opts) { {} }
#     subject { Entities::ExampleEntity.new(organization, connec_client, external_client, opts) }

#     describe 'external to connec!' do
#       let(:external_hash) {
#         {
#           "Id" => '2345uoi'
#           "Salutation" => 'Mr',
#           "FirstName" => 'John',
#           "City" => 'London'
#         }
#       }

#       let (:mapped_external_hash) {
#         {
#           "id" => [{'id' => '2345uoi', 'provider' => organization.oauth_provider, 'realm' => organization.oauth_uid}],
#           "first_name" => "John",
#           "title" => "Mr"
#           "address_work" => {
#             "billing2" => {
#               "city" => 'London'
#             }
#           }
#         }.with_indifferent_access
#       }

#       it { expect(subject.map_to_connec(external_hash)).to eql(mapped_external_hash) }
#     end

#     describe 'connec to external' do
#       let(:connec_hash) {
#         {
#           "first_name" => "John",
#           "title" => "Mr"
#           "address_work" => {
#             "billing2" => {
#               "city" => 'London'
#             }
#           }
#         }
#       }

#       let(:mapped_connec_hash) {
#         {
#           "Salutation" => 'Mr',
#           "FirstName" => 'John',
#           "City" => 'London'
#         }.with_indifferent_access
#       }

#       it { expect(subject.map_to_external(connec_hash)).to eql(mapped_connec_hash) }
#     end
#   end
# end
