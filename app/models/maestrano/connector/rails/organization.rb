module Maestrano::Connector::Rails
  class Organization < ActiveRecord::Base
    # Enable Maestrano for this group
    maestrano_group_via :provider, :uid, :tenant do |group, maestrano|
      group.name = (maestrano.name.blank? ? "Default Group name" : maestrano.name)
      group.tenant = 'default' # To be set from SSO parameter
      #group.country_alpha2 = maestrano.country
      #group.free_trial_end_at = maestrano.free_trial_end_at
      #group.some_required_field = 'some-appropriate-default-value'
    end

    def initialize
      super
      self.synchronized_entities = {}
      External.entities_list.each do |entity|
        self.synchronized_entities[entity.to_sym] = true
      end
    end

    #===================================
    # Encryptions
    #===================================
    # attr_encrypted :oauth_token, key: ::Settings.encryption_key
    # attr_encrypted :refresh_token, key: ::Settings.encryption_key

    #===================================
    # Associations
    #===================================
    has_many :user_organization_rels
    has_many :users, through: :user_organization_rels
    has_many :id_maps, dependent: :destroy
    has_many :synchronizations, dependent: :destroy

    #===================================
    # Validation
    #===================================
    validates :name, presence: true
    validates :tenant, presence: true
    validates :uid, uniqueness: true

    #===================================
    # Serialized field
    #===================================
    serialize :synchronized_entities

    def add_member(user)
      if self.tenant == user.tenant && !self.member?(user)
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

    def last_three_synchronizations_failed?
      arr = self.synchronizations.last(3).map(&:is_error?)
      arr.count == 3 && arr.uniq == [true]
    end

    def last_successful_synchronization
      self.synchronizations.where(status: 'SUCCESS', partial: false).order(updated_at: :desc).first
    end
  end
end