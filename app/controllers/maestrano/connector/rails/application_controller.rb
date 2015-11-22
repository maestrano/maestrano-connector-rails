module Maestrano
  module Connector
    module Rails


      class ApplicationController < ActionController::Base
        include SessionHelper

        protect_from_forgery with: :exception
      end


    end
  end
end