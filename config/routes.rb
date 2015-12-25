Maestrano::Connector::Rails::Engine.routes.draw do
  # maestrano_routes

  #--------------------------------------------------------------------
  # Maintainability issue
  # Should use maestrano_routes but it creates a scoping error with the metadata routes
  get '/maestrano/metadata', to: '/maestrano/rails/metadata#index'
  get '/maestrano/metadata/:tenant', to: '/maestrano/rails/metadata#index', as: 'tenant'

  namespace :maestrano do
    namespace :auth do
      resources :saml, only:[] do
        get 'init', on: :collection
        get 'init/:tenant', on: :collection, to: 'saml#init', as: 'tenant'
        post 'consume', on: :collection
      end
    end

    namespace :account do
      resources :groups, only: [:destroy] do
        resources :users, only: [:destroy], controller: 'group_users'
      end
    end
  end
  #--------------------------------------------------------------------

  match 'signout', to: 'sessions#destroy', as: 'signout', via: [:get, :post]
end