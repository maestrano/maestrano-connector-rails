module Maestrano::Connector::Rails
  module SessionHelper

    def is_admin?(user, organization)
      organization.member?(user) && session[:"role_#{organization.uid}"] && ['Admin', 'Super Admin'].include?(session[:"role_#{organization.uid}"])
    end

    def current_organization
      @current_organization ||= Organization.find_by(uid: session[:org_uid], tenant: session[:tenant])
    end

    def current_user
      @current_user ||= User.find_by(uid: session[:uid], tenant: session[:tenant])
    end

    def is_admin
      @is_admin ||= current_user && current_organization && is_admin?(current_user, current_organization)
    end

  end
end