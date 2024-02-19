# frozen_string_literal: true

require "sidekiq/web"

Rails.application.routes.draw do
  mount HealthMonitor::Engine, at: "/"
  mount Sidekiq::Web => "/sidekiq" # mount Sidekiq::Web in your Rails app

  resources :mediaflux_info, only: [:index]
  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }

  devise_scope :user do
    get "sign_in", to: "devise/sessions#new", as: :new_user_session
    get "sign_out", to: "devise/sessions#destroy", as: :destroy_user_session
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root to: "welcome#index"
  get "help", to: "welcome#help", as: :help

  resources :organizations
  resources :projects
  get "projects/:id/approve", to: "projects#approve", as: :project_approve
  get "projects/:id/confirmation", to: "projects#confirmation", as: :project_confirmation
  get "projects/:id/contents", to: "projects#contents", as: :project_contents
  get "projects/:id/list-contents", to: "projects#list_contents", as: :project_list_contents
  get "projects/:id/revision_confirmation", to: "projects#revision_confirmation", as: :project_revision_confirmation

  namespace :api do
    namespace :v0 do
      resources :projects, only: [:index]
    end
  end
end
