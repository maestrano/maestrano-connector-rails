module Maestrano::Connector::Rails
  class Synchronization < ActiveRecord::Base
    # Keeping only 100 synchronizations per organization
    after_create :clean_synchronizations

    RUNNING_STATUS = 'RUNNING'.freeze
    ERROR_STATUS = 'ERROR'.freeze
    SUCCESS_STATUS = 'SUCCESS'.freeze

    #===================================
    # Associations
    #===================================
    belongs_to :organization

    validates :status, presence: true

    def running?
      status == RUNNING_STATUS
    end

    def error?
      status == ERROR_STATUS
    end

    def success?
      status == SUCCESS_STATUS
    end

    def self.create_running(organization)
      Synchronization.create(organization_id: organization.id, status: RUNNING_STATUS)
    end

    def set_success
      update_attributes(status: SUCCESS_STATUS)
    end

    def set_error(msg)
      update_attributes(status: ERROR_STATUS, message: msg)
    end

    def set_partial
      update_attributes(partial: true)
    end

    def clean_synchronizations
      count = organization.synchronizations.count
      organization.synchronizations.order('id ASC').limit(count - 100).destroy_all if count > 100
    end
  end
end
