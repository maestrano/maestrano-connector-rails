# frozen_string_literal: true
class OauthController < ApplicationController
  # TODO
  # Routes for this controller are not provided by the gem and
  # should be set according to your needs

  def request_omniauth
    return redirect_to root_url unless is_admin

    # TODO
    # Perform oauth request here. The oauth process should be able to
    # remember the organization, either by a param in the request or using
    # a session
  end

  def create_omniauth
    org_uid = '' # TODO
    organization = Maestrano::Connector::Rails::Organization.find_by_uid_and_tenant(org_uid, current_user.tenant)

    return redirect_to root_url unless organization && is_admin?(current_user, organization)

    # TODO
    # Update organization with oauth params
    # Should at least set oauth_uid, oauth_token and oauth_provider
  end

  def destroy_omniauth
    organization = Maestrano::Connector::Rails::Organization.find_by_id(params[:organization_id])
    organization.clear_omniauth if organization && is_admin?(current_user, organization)

    redirect_to root_url
  end
end
