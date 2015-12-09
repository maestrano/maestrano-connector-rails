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
    ### 1)Find or create the user and the group
    ### --
    ### The class method 'find_or_create_for_maestrano' is provided
    ### by the maestrano-rails gem on the model you have maestrano-ized.
    ### The method uses the mapping defined in the model 'maestrano_*_via' 
    ### block to create the resource if it does not exist
    ### The 'user_auth_hash' and 'group_auth_hash' methods are provided
    ### by the controller.
    ### --
    # user = User.find_or_create_for_maestrano(user_auth_hash)
    # organization = Organization.find_or_create_for_maestrano(group_auth_hash)
    #
    #
    ### 2) Add the user to the group if not already a member
    ### --
    ### The 'user_group_rel_hash' method is provided by the controller.
    ### The role attribute provided by maestrano is one of the following: 
    ### 'Member', 'Power User', 'Admin', 'Super Admin'
    ### The 'member_of?' and 'add_member' methods are not provided by 
    ### maestrano and are left to you to implement on your models
    ### --
    # unless user.member_of?(organization)
    #   organization.add_member(user,role: user_group_rel_hash[:role])
    # end
    #
    #
    ### Sign the user in and redirect to application root
    ### --
    ### The 'sign_in' method is not provided by maestrano but should already
    ### be there if you are using an authentication framework like Devise
    ### --
    # sign_in(user)
    # redirect_to root_path
    
    raise NotImplemented.new("The consume action should be customized to fit your application needs")
  end
end