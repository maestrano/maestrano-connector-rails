module Maestrano::Connector::Rails::Maestrano::Auth
  class SamlController < ::Maestrano::Rails::SamlBaseController

    #== POST '/maestrano/auth/saml/consume'
    def consume
      user = Maestrano::Connector::Rails::User.find_or_create_for_maestrano(user_auth_hash)
      organization = Maestrano::Connector::Rails::Organization.find_or_create_for_maestrano(group_auth_hash)

      unless organization.member?(user)
        organization.add_member(user)
      end

      session[:uid] = user.uid
      session[:org_uid] = organization.uid
      session[:"role_#{organization.uid}"] = user_group_rel_hash[:role]
      session[:tenant] = 'default' #TODO change

      redirect_to main_app.root_path
    end
  end
end