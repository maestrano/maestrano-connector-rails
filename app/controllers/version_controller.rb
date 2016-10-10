class VersionController < ApplicationController
  def index
    framework_version = Gem.loaded_specs['maestrano-connector-rails'].version.version
    respond_to do |format|
      format.html { render text: "framework_version=#{framework_version}\n" }
      format.json { render json: {framework_version: framework_version, env: Rails.env} }
    end
  end
end
