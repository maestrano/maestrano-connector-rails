class OauthController < ApplicationController

  # TODO
  # Routes for this controller are not provided by the gem and
  # should be set according to your needs

  def request_omniauth
    if is_admin
      # TODO
      # Perform oauth request here. The oauth process should be able to
      # remember the organization, either by a param in the request or using
      # a session
    else
      redirect_to root_url
    end
  end

  def create_omniauth
    org_uid = '' # TODO
    organization = Maestrano::Connector::Rails::Organization.find_by_uid_and_tenant(org_uid, current_user.tenant)

    if organization && is_admin?(current_user, organization)
      # TODO
      # Update organization with oauth params
      # Should at least set oauth_uid, oauth_token and oauth_provider
    end

    redirect_to root_url
  end

  def destroy_omniauth
    organization = Maestrano::Connector::Rails::Organization.find_by_id(params[:organization_id])

    if organization && is_admin?(current_user, organization)
      organization.oauth_uid = nil
      organization.oauth_token = nil
      organization.refresh_token = nil
      organization.sync_enabled = false
      organization.save
    end

    redirect_to root_url
  end
end