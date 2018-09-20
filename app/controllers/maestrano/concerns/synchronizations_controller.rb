# frozen_string_literal: true

module Maestrano
  module Concerns
    module SynchronizationsController
      extend ActiveSupport::Concern

      #==================================================================
      # Included methods
      #==================================================================
      # 'included do' causes the included code to be evaluated in the
      # context where it is included rather than being executed in the
      # module's context
      included do
      end

      #==================================================================
      # Class methods
      #==================================================================
      module ClassMethods
      end

      #==================================================================
      # Instance methods
      #==================================================================
      def show
        tenant = params[:tenant]
        uid = params[:id]
        organization = Maestrano::Connector::Rails::Organization.find_by(uid: uid, tenant: tenant)
        return render json: {errors: [{message: 'Organization not found', code: 404}]}, status: :not_found unless organization

        status = organization_status organization

        render_organization_sync(organization, status, 200)
      end

      def create
        tenant = params[:tenant]
        uid = params[:group_id]
        opts = params[:opts] || {}
        organization = Maestrano::Connector::Rails::Organization.find_by(uid: uid, tenant: tenant)
        return render json: {errors: [{message: 'Organization not found', code: 404}]}, status: :not_found unless organization

        organization.sync_enabled = organization.synchronized_entities.values.any? { |settings| settings.values.any? { |v| v } }
        organization.save if organization.sync_enabled_changed?

        status = organization_status(organization)

        unless %w[RUNNING ENQUEUED].include?(status)
          Maestrano::Connector::Rails::SynchronizationJob.perform_later(organization.id, opts.with_indifferent_access)
          status = 'ENQUEUED'
        end

        render_organization_sync(organization, status, 201)
      end

      def update_metadata
        tenant = params[:tenant]
        uid = params[:group_id]
        organization = Maestrano::Connector::Rails::Organization.find_by(uid: uid, tenant: tenant)
        return render json: {errors: [{message: 'Organization not found', code: 404}]}, status: :not_found unless organization

        organization.set_instance_metadata
        organization.reset_synchronized_entities
        render_organization_sync(organization, status, 200)
      end

      def toggle_sync
        tenant = params[:tenant]
        uid = params[:group_id]
        organization = Maestrano::Connector::Rails::Organization.find_by(uid: uid, tenant: tenant)
        return render json: {errors: [{message: 'Organization not found', code: 404}]}, status: :not_found unless organization

        organization.toggle(:sync_enabled)
        organization.save
        status = organization_status organization
        render_organization_sync(organization, status, 200)
      end

      private

      def render_organization_sync(organization, status, code)
        h = {
          group_id: organization.uid,
          sync_enabled: organization.sync_enabled,
          status: status
        }
        last_sync = organization.synchronizations.last
        if last_sync
          h[:message] = last_sync.message
          h[:updated_at] = last_sync.updated_at
        end

        render json: h, status: code
      end

      def organization_status(organization)
        if Maestrano::Connector::Rails::SynchronizationJob.find_running_job(organization.id)
          'RUNNING'
        elsif Maestrano::Connector::Rails::SynchronizationJob.find_job(organization.id)
          'ENQUEUED'
        else
          organization.synchronizations.last&.status || 'DISABLED'
        end
      end
    end
  end
end
