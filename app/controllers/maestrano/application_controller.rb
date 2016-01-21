module Maestrano
  class ApplicationController < ActionController::Base
    include SessionHelper

    protect_from_forgery with: :exception
  end
end