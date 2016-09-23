class Maestrano::SynchronizationsController < Maestrano::Rails::WebHookController
  def show
    tenant = params[:tenant]
    uid = params[:id]
    organization = Maestrano::Connector::Rails::Organization.find_by_uid_and_tenant(uid, tenant)
    return render json: {errors: [{message: 'Organization not found', code: 404}]}, status: :not_found unless organization

    status = organization_status organization

    render_organization_sync(organization, status, 200)
  end

  def create
    tenant = params[:tenant]
    uid = params[:group_id]
    opts = params[:opts] || {}
    organization = Maestrano::Connector::Rails::Organization.find_by_uid_and_tenant(uid, tenant)
    return render json: {errors: [{message: 'Organization not found', code: 404}]}, status: :not_found unless organization

    status = Maestrano::Connector::Rails::SynchronizationJob.find_running_job(organization.id) ? 'RUNNING' : 'ENQUEUED'


    Maestrano::Connector::Rails::SynchronizationJob.perform_later(organization.id, opts.with_indifferent_access) unless Maestrano::Connector::Rails::SynchronizationJob.enqueued?(organization.id)
    render_organization_sync(organization, status, 201)
  end

  def toggle_sync
    tenant = params[:tenant]
    uid = params[:group_id]
    organization = Maestrano::Connector::Rails::Organization.find_by_uid_and_tenant(uid, tenant)
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
      last_sync = organization.synchronizations.last
      if Maestrano::Connector::Rails::SynchronizationJob.find_running_job(organization.id)
        'RUNNING'
      elsif Maestrano::Connector::Rails::SynchronizationJob.find_job(organization.id)
        'ENQUEUED'
      else
        last_sync ? last_sync.status : 'DISABLED'
      end
    end
end
