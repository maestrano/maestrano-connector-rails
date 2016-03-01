Rails.application.routes.draw do
  mount Maestrano::Connector::Rails::Engine, at: '/'

  root 'home#index'
  get 'home/index' => 'home#index'
  get 'home/redirect_to_external' => 'home#redirect_to_external'
  get 'home/index' => 'home#index'
  put 'home/update' => 'home#update'
  post 'home/synchronize' => 'home#synchronize'
  put 'home/toggle_sync' => 'home#toggle_sync'

  get 'synchronizations/index' => 'synchronizations#index'
  get 'shared_entities/index' => 'shared_entities#index'
end