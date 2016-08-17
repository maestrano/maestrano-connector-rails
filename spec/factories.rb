FactoryGirl.define do
  factory :user, class: Maestrano::Connector::Rails::User do
    email 'email@example.com'
    tenant 'default'
  end

  factory :organization, class: Maestrano::Connector::Rails::Organization do
    name 'My company'
    tenant 'default'
    sequence(:uid) { |n| "cld-11#{n}" }
    oauth_uid 'sfuiy765'
    oauth_provider 'this_app'
  end

  factory :user_organization_rel, class: Maestrano::Connector::Rails::UserOrganizationRel do
    association :user
    association :organization
  end

  factory :idmap, class: Maestrano::Connector::Rails::IdMap do
    sequence(:connec_id) { |n| "#{n}6798-ada6-te43#{n}" }
    connec_entity 'person'
    sequence(:external_id) { |n| "#{n}4567ada66#{n}" }
    external_entity 'contact'
    last_push_to_external 2.days.ago
    last_push_to_connec 1.day.ago
    association :organization
  end

  factory :synchronization, class: Maestrano::Connector::Rails::Synchronization do
    association :organization
    status 'SUCCESS'
    partial false
  end
end
