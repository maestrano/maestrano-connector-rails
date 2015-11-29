Maestrano::Connector::Rails::Engine.routes.draw do
  maestrano_routes

  match 'signout', to: 'sessions#destroy', as: 'signout', via: [:get, :post]
end
