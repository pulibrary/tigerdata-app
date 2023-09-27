# frozen_string_literal: true
Rails.application.routes.draw do
  resources :mediaflux_info, only: [:index]
  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }

  devise_scope :user do
    get "sign_in", to: "devise/sessions#new", as: :new_user_session
    get "sign_out", to: "devise/sessions#destroy", as: :destroy_user_session
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root to: "welcome#index"

  resources :organizations
  resources :projects

  # get "set-note/:id", to: "welcome#set_note", as: :set_note
  # get "create-asset", to: "welcome#create_asset", as: :create_asset
  # get "create-collection-asset", to: "welcome#create_collection_asset", as: :create_collection_asset

  get "dashboards/:role", to: "dashboards#show"

  namespace :api do
    namespace :v0 do
      resources :projects, only: [:index]
    end
  end
end
