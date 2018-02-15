Rails.application.routes.draw do
  mount Maestrano::Connector::Rails::Engine, at: '/'

  # Default Connector pages
  root 'home#index'

  namespace 'home' do
    get 'index' => 'home#index'
    get 'redirect_to_external' => 'home#redirect_to_external'
    put 'update' => 'home#update'
    post 'synchronize' => 'home#synchronize'
  end

  get 'synchronizations/index' => 'synchronizations#index'
  get 'shared_entities/index' => 'shared_entities#index'

  # OAuth workflow pages
  match 'auth/:provider/request', to: 'oauth#create_omniauth', via: %i[get post]
  match 'signout_omniauth', to: 'oauth#destroy_omniauth', as: 'signout_omniauth', via: %i[get post]
  post 'auth/auth', to: 'auth#auth'

  # Sidekiq Admin
  require 'sidekiq/web'
  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    username == ENV['SIDEKIQ_USERNAME'] && password == ENV['SIDEKIQ_PASSWORD']
  end
  mount Sidekiq::Web => '/sidekiq'
end
