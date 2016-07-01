require 'spec_helper'

describe Maestrano::DependanciesController, type: :controller do
  routes { Maestrano::Connector::Rails::Engine.routes }

  describe 'index' do
    subject { get :index }

    context 'without authentication' do
      before {
        controller.class.before_filter :authenticate_maestrano!
      }

      it 'respond with unauthorized' do
        subject
        expect(response.status).to eq(401)
      end
    end

    context 'with authentication' do
      before {
        controller.class.skip_before_filter :authenticate_maestrano!
      }

      it 'renders the dependancies hash' do
        subject
        expect(response.body).to eql(Maestrano::Connector::Rails::ConnecHelper.dependancies.to_json)
      end
    end
  end
end