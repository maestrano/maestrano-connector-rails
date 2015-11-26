module Maestrano::Connector::Rails
  class SessionsController < ApplicationController
    # Logout
    def destroy
      session.delete(:uid)
      session.delete(:"role_#{session[:org_uid]}")
      session.delete(:org_uid)
      session.delete(:tenant)
      @current_user = nil

      redirect_to root_url
    end
  end
end