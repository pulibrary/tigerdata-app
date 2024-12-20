# frozen_string_literal: true

require "sidekiq/web"

Rails.application.routes.draw do
  mount Flipflop::Engine => "/features"
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
  post "emulate", to: "welcome#emulate", as: :emulate
  get "styles_preview", to: "welcome#styles_preview", as: :styles_preview
  post "dash_classic", to: "welcome#dash_classic", as: :dash_classic
  post "dash_project", to: "welcome#dash_project", as: :dash_project
  post "dash_admin", to: "welcome#dash_admin", as: :dash_admin

  resources :organizations
  resources :projects
  get "projects/:id/approve", to: "projects#approve", as: :project_approve
  get "projects/:id/confirmation", to: "projects#confirmation", as: :project_confirmation
  get "projects/:id/details", to: "projects#details", as: :project_details
  get "projects/:id/list-contents", to: "projects#list_contents", as: :project_list_contents
  get "projects/:id/revision_confirmation", to: "projects#revision_confirmation", as: :project_revision_confirmation
  get "projects/file_list_download/:job_id", to: "projects#file_list_download", as: :project_file_list_download
  get "projects/:id/approval_received", to: "projects#approval_received", as: :project_approval_received
  get "projects/:id/create-script", to: "projects#create_script", as: :project_create_script

  namespace :api do
    namespace :v0 do
      resources :projects, only: [:index]
    end
  end

  mount ActionCable.server => "/cable"
  get "mediaflux_extra", to: "users/mediaflux_callbacks#cas", as: :mediaflux_extra
  get "mediaflux_passthru", to: "users/mediaflux_callbacks#passthru", as: :mediaflux_passthru
end
