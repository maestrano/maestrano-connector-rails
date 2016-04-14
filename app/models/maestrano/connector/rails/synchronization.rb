module Maestrano::Connector::Rails
  class Synchronization < ActiveRecord::Base
    # Keeping only 100 synchronizations per organization
    after_create :clean_synchronizations

    #===================================
    # Associations
    #===================================
    belongs_to :organization

    validates :status, presence: true

    def is_running?
      self.status == 'RUNNING'
    end

    def is_error?
      self.status == 'ERROR'
    end

    def is_success?
      self.status == 'SUCCESS'
    end

    def self.create_running(organization)
      Synchronization.create(organization_id: organization.id, status: 'RUNNING')
    end

    def set_success
      self.update_attributes(status: 'SUCCESS')
    end

    def set_error(msg)
      self.update_attributes(status: 'ERROR', message: msg)
    end

    def set_partial
      self.update_attributes(partial: true)
    end

    def clean_synchronizations
      count = self.organization.synchronizations.count
      if count > 100
        self.organization.synchronizations.limit(count - 100).destroy_all
      end
    end
  end
end