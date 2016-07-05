class Maestrano::SynchronizationsController < Maestrano::Rails::WebHookController
  def show
    uid = params[:id]
    organization = Maestrano::Connector::Rails::Organization.find_by_uid(uid)
    return render json: {errors: {message: "Organization not found", code: 404}}, status: :not_found unless organization

    h = {
      group_id: organization.uid,
      sync_enabled: organization.sync_enabled
    }

    last_sync = organization.synchronizations.last
    if last_sync
      h.merge!(
        status: last_sync.status,
        message: last_sync.message,
        updated_at: last_sync.updated_at
      )
    end

    render json: h
  end

  def create
    uid = params[:group_id]
    opts = params[:opts] || {}
    organization = Maestrano::Connector::Rails::Organization.find_by_uid(uid)
    return render json: {errors: {message: "Organization not found", code: 404}}, status: :not_found unless organization

    Maestrano::Connector::Rails::SynchronizationJob.perform_later(organization, opts.with_indifferent_access)
    head :created
  end

  def toggle_sync
    uid = params[:group_id]
    organization = Maestrano::Connector::Rails::Organization.find_by_uid(uid)
    return render json: {errors: {message: "Organization not found", code: 404}}, status: :not_found unless organization

    organization.toggle(:sync_enabled)
    organization.save

    render json: {sync_enabled: organization.sync_enabled}
  end
end
