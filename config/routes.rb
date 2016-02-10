Maestrano::Connector::Rails::Engine.routes.draw do
  maestrano_routes

  namespace :maestrano do
  	match 'signout', to: 'sessions#destroy', as: 'signout', via: [:get, :post]
    post 'connec/notifications/:tenant' => 'connec#notifications'
  end
end