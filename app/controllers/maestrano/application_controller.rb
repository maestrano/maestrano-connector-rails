module Maestrano
  class ApplicationController < ActionController::Base
    include Maestrano::Connector::Rails::SessionHelper

    protect_from_forgery with: :exception
  end
end