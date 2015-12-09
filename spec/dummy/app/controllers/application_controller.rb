class ApplicationController < ActionController::Base
  helper Maestrano::Connector::Rails::Engine.helpers
  include Maestrano::Connector::Rails::SessionHelper

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
end
