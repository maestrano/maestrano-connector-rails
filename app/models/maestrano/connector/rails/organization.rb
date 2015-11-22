module Maestrano
  module Connector
    module Rails


      class Organization < ActiveRecord::Base
        # Enable Maestrano for this group
        maestrano_group_via :provider, :uid do |group, maestrano|
          group.name = (maestrano.name.blank? ? "Default Group name" : maestrano.name)
          group.tenant = 'default' # To be set from SSO parameter
          #group.country_alpha2 = maestrano.country
          #group.free_trial_end_at = maestrano.free_trial_end_at
          #group.some_required_field = 'some-appropriate-default-value'
        end

        # Define all the entities that the connector can synchronize
        # If you add new entities, you need to generate
        # a migration to add them to existing organizations
        ENTITIES = %w(organization person)

        def initialize
          super
          self.synchronized_entities = {}
          ENTITIES.each do |entity|
            self.synchronized_entities[entity.to_sym] = true
          end
        end

        #===================================
        # Associations
        #===================================
        has_many :user_organization_rels
        has_many :users, through: :user_organization_rels

        #===================================
        # Validation
        #===================================
        validates :name, presence: true

        #===================================
        # Serialized field
        #===================================
        serialize :synchronized_entities

        def add_member(user)
          unless self.member?(user)
            self.user_organization_rels.create(user:user)
          end
        end

        def member?(user)
          self.user_organization_rels.where(user_id:user.id).count > 0
        end

        def remove_member(user)
          self.user_organization_rels.where(user_id:user.id).delete_all
        end

        def from_omniauth(auth)
          self.oauth_provider = auth.provider
          self.oauth_uid = auth.uid
          self.oauth_token = auth.credentials.token
          self.refresh_token = auth.credentials.refresh_token
          self.instance_url = auth.credentials.instance_url
          self.save!
        end
      end


    end
  end
end