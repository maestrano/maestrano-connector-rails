# frozen_string_literal: true

module Maestrano
  module Api
    class AccountController < ApiController
      include Maestrano::Api::Concerns::AccountController

      # def setup_form
      # TODO return the json angular schema form
      # that will be used for the user to link their account
      # See https://github.com/json-schema-form/angular-schema-form/
      # end

      # def link_account
      # TODO similar to oauth_controller#request, method that allows
      # the user to link their account.
      # Params will be the ones from the setup_form +
      # 'org-uid': the channel_id (e.g: org-fbba)
      # end
    end
  end
end
