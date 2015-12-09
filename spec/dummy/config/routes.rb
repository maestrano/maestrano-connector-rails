Rails.application.routes.draw do
  mount Maestrano::Connector::Rails::Engine, at: '/'

  root 'home#index'
  get 'home/index' => 'home#index'
  get 'admin/index' => 'admin#index'
  put 'admin/update' => 'admin#update'
  post 'admin/synchronize' => 'admin#synchronize'
end
