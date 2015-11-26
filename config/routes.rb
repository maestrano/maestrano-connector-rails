Maestrano::Connector::Rails::Engine.routes.draw do
  #maestrano_routes #TODO

  root 'home#index'

  get 'home/index' => 'home#index'

  get 'admin/index' => 'admin#index'
  put 'admin/update' => 'admin#update'
  post 'admin/synchronize' => 'admin#synchronize'

  match 'signout', to: 'sessions#destroy', as: 'signout', via: [:get, :post]
end
