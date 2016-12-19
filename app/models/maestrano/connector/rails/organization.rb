module Maestrano::Connector::Rails
  class Organization < ActiveRecord::Base
    # Enable Maestrano for this group
    maestrano_group_via :provider, :uid, :tenant do |group, maestrano|
      group.name = (maestrano.name.blank? ? 'Default Group name' : maestrano.name)
      group.tenant = 'default' # To be set from SSO parameter
      group.org_uid = maestrano.org_uid # Maestrano organization UID

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
    attr_encrypted :oauth_token, key: Rails.env.test? ? 'just_a_string' : ::Settings.encryption_key1
    attr_encrypted :refresh_token, key: Rails.env.test? ? 'just_a_string' : ::Settings.encryption_key2

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
    validates :uid, uniqueness: {scope: :tenant}
    validates :oauth_uid, uniqueness: {allow_blank: true, message: 'This account has already been linked'}

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
      user_organization_rels.where(user_id: user.id).count.positive?
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
      self.save
    end

    def clear_omniauth
      self.oauth_uid = nil
      self.oauth_token = nil
      self.refresh_token = nil
      self.sync_enabled = false
      self.save
    end

    # Enable historical data sharing (prior to account linking)
    def enable_historical_data(enabled)
      # Historical data sharing cannot be unset
      return if self.historical_data

      if enabled
        self.date_filtering_limit = nil
        self.historical_data = true
      else
        self.date_filtering_limit ||= Time.now.getlocal
      end
    end

    def last_three_synchronizations_failed?
      arr = synchronizations.last(3).map(&:error?)
      arr.count == 3 && arr.uniq == [true]
    end

    def last_successful_synchronization
      synchronizations.where(status: 'SUCCESS', partial: false).order(updated_at: :desc).first
    end

    def last_synchronization_date
      last_successful_synchronization&.updated_at || date_filtering_limit
    end

    def reset_synchronized_entities
      synchronized_entities.slice!(*External.entities_list.map(&:to_sym))
      External.entities_list.each { |entity| synchronized_entities[entity.to_sym] ||= false }
      save
    end
  end
end
