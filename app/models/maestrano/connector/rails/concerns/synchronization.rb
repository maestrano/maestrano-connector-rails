module Maestrano::Connector::Rails::Concerns::Synchronization
  extend ActiveSupport::Concern

  included do
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
  end

  module ClassMethods
    def create_running(organization)
      Maestrano::Connector::Rails::Synchronization.create(organization_id: organization.id, status: RUNNING_STATUS)
    end
  end

  def running?
    status == RUNNING_STATUS
  end

  def error?
    status == ERROR_STATUS
  end

  def success?
    status == SUCCESS_STATUS
  end

  def mark_as_success
    update(status: SUCCESS_STATUS)
  end

  def mark_as_error(msg)
    update(status: ERROR_STATUS, message: msg)
  end

  def mark_as_partial
    update(partial: true)
  end

  def clean_synchronizations
    count = organization.synchronizations.count
    organization.synchronizations.order('id ASC').limit(count - 100).destroy_all if count > 100
  end
end
