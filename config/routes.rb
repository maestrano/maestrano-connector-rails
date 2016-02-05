Maestrano::Connector::Rails::Engine.routes.draw do
  maestrano_routes

  namespace :maestrano do
    post 'connec/notifications/:tenant' => 'connec#notifications'
  end

  match 'signout', to: 'sessions#destroy', as: 'signout', via: [:get, :post]
end