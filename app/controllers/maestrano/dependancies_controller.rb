class Maestrano::DependanciesController < Maestrano::Rails::WebHookController
  def index
    render json: Maestrano::Connector::Rails::ConnecHelper.dependancies
  end
end
