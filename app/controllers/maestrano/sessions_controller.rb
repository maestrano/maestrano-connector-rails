module Maestrano
  class SessionsController < ApplicationController
    # Logout
    def destroy
      session.delete(:uid)
      session.delete(:"role_#{session[:org_uid]}")
      session.delete(:org_uid)
      session.delete(:tenant)
      session.delete(:current_user_id)
      @current_user = nil

      redirect_to root_url
    end
  end
end