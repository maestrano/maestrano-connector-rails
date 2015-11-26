module Maestrano::Connector::Rails
  class ApplicationController < ActionController::Base
    include SessionHelper

    protect_from_forgery with: :exception
  end
end