class VersionController < ApplicationController
  def index
    framework_version = Gem.loaded_specs['maestrano-connector-rails'].version.version
    branch = ENV['GIT_BRANCH']
    commit = ENV['GIT_COMMIT_ID']

    respond_to do |format|
      format.html { render text: "framework_version=#{framework_version}\nci_branch=#{branch}\nci_commit=#{commit}\nenv=#{Rails}\nnv, ruby_version=#{RUBY_VERSION}\nruby_engine=#{RUBY_ENGINE}\n" }
      format.json { render json: {framework_version: framework_version, ci_branch: branch, ci_commit: commit, env: Rails.env, ruby_version: RUBY_VERSION, ruby_engine: RUBY_ENGINE} }
    end
  end
end
