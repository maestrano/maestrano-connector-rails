Maestrano::Connector::Rails::Engine.routes.draw do
  maestrano_routes

  get 'version', to: 'version#index'

  namespace :maestrano do
    match 'signout', to: 'sessions#destroy', as: 'signout', via: %i[get post]
    post 'connec/notifications/:tenant' => 'connec#notifications'

    resources :dependancies, only: [:index]

    scope ':tenant' do
      resources :synchronizations, only: %i[show create] do
        collection do
          put :toggle_sync
          put :update_metadata
        end
      end
    end

    namespace :api do
      get 'account/setup_form'
      post 'account/link_account'
      post 'account/unlink_account'

      jsonapi_resources :organizations
      jsonapi_resources :users
      jsonapi_resources :synchronizations
      jsonapi_resources :id_maps
    end
  end
end
