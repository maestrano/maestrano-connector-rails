class OauthController < ApplicationController

  # TODO
  # Routes for this controller are not provided by the gem and
  # should be set according to your needs

  def request_omniauth
    org_uid = params[:org_uid]
    organization = Maestrano::Connector::Rails::Organization.find_by_uid(org_uid)

    if organization && is_admin?(current_user, organization)
      # TODO
      # Perform oauth request here. The oauth process should be able to
      # remember the organization, either by a param in the request or with
      # the session
    else
      redirect_to root_url
    end
  end

  def create_omniauth
    org_uid = '' # TODO
    organization = Maestrano::Connector::Rails::Organization.find_by_uid(org_uid)

    if organization && is_admin?(current_user, organization)
      # TODO
      # Update organization with oauth params
    end

    redirect_to root_url
  end

  def destroy_omniauth
    organization = Maestrano::Connector::Rails::Organization.find(params[:organization_id])

    if organization && is_admin?(current_user, organization)
      organization.oauth_uid = nil
      organization.oauth_token = nil
      organization.refresh_token = nil
      organization.save
    end

    redirect_to root_url
  end
end