class Maestrano::Auth::SamlController < Maestrano::Rails::SamlBaseController
  def init
    session[:settings] = !!params[:settings]
    super
  end

  #== POST '/maestrano/auth/saml/consume'
  # Final phase of the Single Sign-On handshake. Find or create
  # the required resources (user and group) and sign the user
  # in
  def consume
    params[:tenant] ||= 'default'
    user = Maestrano::Connector::Rails::User.find_or_create_for_maestrano(user_auth_hash, params[:tenant])
    organization = Maestrano::Connector::Rails::Organization.find_or_create_for_maestrano(group_auth_hash, params[:tenant])
    if user && organization
      organization.add_member(user) unless organization.member?(user)

      session[:tenant] = params[:tenant]
      session[:uid] = user.uid
      session[:org_uid] = organization.uid
      session[:"role_#{organization.uid}"] = user_group_rel_hash[:role]
    end

    if session[:settings]
      session.delete(:settings)
      redirect_to main_app.root_path
    elsif current_organization&.oauth_uid && current_organization&.sync_enabled
      redirect_to main_app.home_redirect_to_external_path
    else
      redirect_to main_app.root_path
    end
  end
end
