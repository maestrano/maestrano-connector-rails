module Maestrano
  module Connector
    module Rails


      module SessionHelper

        def is_admin?(user, organization)
          organization.member?(user) && session[:"role_#{organization.uid}"] && ['Admin', 'Super Admin'].include?(session[:"role_#{organization.uid}"])
        end

        def current_organization
          Organization.find_by(uid: session[:org_uid], tenant: session[:tenant])
        end

        def current_user
          User.find_by(uid: session[:uid], tenant: session[:tenant])
        end

      end


    end
  end
end