module Maestrano::Connector::Rails
  class Organization < ActiveRecord::Base
    # Enable Maestrano for this group
    maestrano_group_via :provider, :uid, :tenant do |group, maestrano|
      group.name = (maestrano.name.blank? ? 'Default Group name' : maestrano.name)
      group.tenant = 'default' # To be set from SSO parameter
      # group.country_alpha2 = maestrano.country
      # group.free_trial_end_at = maestrano.free_trial_end_at
      # group.some_required_field = 'some-appropriate-default-value'
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
    attr_encrypted_options[:mode] = :per_attribute_iv_and_salt
    attr_encrypted :oauth_token, key: ::Settings.encryption_key1
    attr_encrypted :refresh_token, key: ::Settings.encryption_key2

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

    def displayable_synchronized_entities
      result = {}
      synchronized_entities.each do |entity, boolean|
        begin
          clazz = "Entities::#{entity.to_s.titleize.split.join}".constantize
        rescue
          next
        end
        result[entity] = {value: boolean, connec_name: clazz.public_connec_entity_name, external_name: clazz.public_external_entity_name}
      end
      result
    end

    def add_member(user)
      user_organization_rels.create(user: user) if tenant == user.tenant && !member?(user)
    end

    def member?(user)
      user_organization_rels.where(user_id: user.id).count > 0
    end

    def remove_member(user)
      user_organization_rels.where(user_id: user.id).delete_all
    end

    def from_omniauth(auth)
      self.oauth_provider = auth.provider
      self.oauth_uid = auth.uid
      self.oauth_token = auth.credentials.token
      self.refresh_token = auth.credentials.refresh_token
      self.instance_url = auth.credentials.instance_url
      save!
    end

    def clear_omniauth
      self.oauth_uid = nil
      self.oauth_token = nil
      self.refresh_token = nil
      self.sync_enabled = false
      self.save
    end

    def check_historical_data(checkbox_ticked)
      return if self.historical_data
      # checkbox_ticked is a boolean
      if checkbox_ticked
        self.date_filtering_limit = nil
        self.historical_data = true
      else
        self.date_filtering_limit ||= Time.now.getlocal
      end
      self.save
    end

    def last_three_synchronizations_failed?
      arr = synchronizations.last(3).map(&:error?)
      arr.count == 3 && arr.uniq == [true]
    end

    def last_successful_synchronization
      synchronizations.where(status: 'SUCCESS', partial: false).order(updated_at: :desc).first
    end

    def last_synchronization_date
      (last_successful_synchronization && last_successful_synchronization.updated_at) || date_filtering_limit
    end
  end
end
