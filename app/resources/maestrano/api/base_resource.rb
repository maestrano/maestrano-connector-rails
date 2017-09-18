module Maestrano
  module Api
    class BaseResource < JSONAPI::Resource
      abstract
      include Pundit::Resource
    end
  end
end
