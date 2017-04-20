module Maestrano::Connector::Rails::Concerns::User
  extend ActiveSupport::Concern

  included do

  	# Enable Maestrano for this user
    maestrano_user_via :provider, :uid, :tenant do |user, maestrano|
      user.uid = maestrano.uid
      user.provider = maestrano.provider
      user.first_name = maestrano.first_name
      user.last_name = maestrano.last_name
      user.email = maestrano.email
      user.tenant = 'default' # To be set from SSO parameter
    end

   	#===================================
   	# Associations
   	#===================================
   	has_many :user_organization_rels, class_name: 'Maestrano::Connector::Rails::UserOrganizationRel'
   	has_many :organizations, through: :user_organization_rels, class_name: 'Maestrano::Connector::Rails::Organization'

   	#===================================
   	# Validation
   	#===================================
   	validates :email, presence: true
   	validates :tenant, presence: true
  end
end
