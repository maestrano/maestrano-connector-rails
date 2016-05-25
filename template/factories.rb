FactoryGirl.define do

  factory :organization, class: Maestrano::Connector::Rails::Organization do
    name "My company"
    tenant "default"
    sequence(:uid) { |n| "cld-11#{n}" }
    oauth_uid 'sfuiy765'
    oauth_provider 'this_app'
  end

  factory :idmap, class: Maestrano::Connector::Rails::IdMap do
    connec_entity 'person'
    external_id '4567ada66'
    external_entity 'contact'
    last_push_to_external 2.day.ago
    last_push_to_connec 1.day.ago
    association :organization
  end

  factory :synchronization, class: Maestrano::Connector::Rails::Synchronization do
    association :organization
    status 'SUCCESS'
    partial false
  end
end