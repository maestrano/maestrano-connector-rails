class Maestrano::Auth::SamlController < Maestrano::Rails::SamlBaseController
  #== POST '/maestrano/auth/saml/consume'
  # Final phase of the Single Sign-On handshake. Find or create
  # the required resources (user and group) and sign the user
  # in
  #
  # This action is left to you to customize based on your application
  # requirements. Below is presented a potential way of writing 
  # the action.
  #
  # Assuming you have enabled maestrano on a user model
  # called 'User' and a group model called 'Organization'
  # the action could be written the following way
  def consume
    params[:tenant] ||= 'default'
    user = Maestrano::Connector::Rails::User.find_or_create_for_maestrano(user_auth_hash, params[:tenant])
    organization = Maestrano::Connector::Rails::Organization.find_or_create_for_maestrano(group_auth_hash, params[:tenant])
    if user && organization
      unless organization.member?(user)
        organization.add_member(user)
      end

      session[:tenant] = params[:tenant]
      session[:uid] = user.uid
      session[:org_uid] = organization.uid
      session[:"role_#{organization.uid}"] = user_group_rel_hash[:role]
    end
    
    redirect_to main_app.root_path
  end
end