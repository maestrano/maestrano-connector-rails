Rails.application.routes.draw do
  mount Maestrano::Connector::Rails::Engine, at: '/'

  # health check
  health_check_routes

  # Default Connector pages
  root 'home#index'
  get 'home/index' => 'home#index'
  get 'home/redirect_to_external' => 'home#redirect_to_external'
  get 'home/index' => 'home#index'
  put 'home/update' => 'home#update'
  post 'home/synchronize' => 'home#synchronize'
  get 'synchronizations/index' => 'synchronizations#index'
  get 'shared_entities/index' => 'shared_entities#index'

  # OAuth workflow pages
  match 'auth/:provider/request', to: 'oauth#create_omniauth', via: %i[get post]
  match 'signout_omniauth', to: 'oauth#destroy_omniauth', as: 'signout_omniauth', via: %i[get post]
  post 'auth/auth', to: 'auth#auth'

  # Sidekiq Admin
  require 'sidekiq/web'
  require 'sidekiq/cron/web'
  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    Rack::Utils.secure_compare(::Digest::SHA256.hexdigest(username), ::Digest::SHA256.hexdigest(ENV['SIDEKIQ_USERNAME'])) &
      Rack::Utils.secure_compare(::Digest::SHA256.hexdigest(password), ::Digest::SHA256.hexdigest(ENV['SIDEKIQ_PASSWORD']))
  end
  mount Sidekiq::Web => '/sidekiq'
end
