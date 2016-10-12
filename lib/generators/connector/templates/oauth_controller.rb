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
    return redirect_to root_url unless is_admin

    # TODO
    # Update current_organization with oauth params
    # Should at least set oauth_uid, oauth_token and oauth_provider
  end

  def destroy_omniauth
    return redirect_to root_url unless is_admin

    current_organization.clear_omniauth

    redirect_to root_url
  end
end
