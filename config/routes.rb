# frozen_string_literal: true

require "sidekiq/web"

# rubocop:disable Metrics/BlockLength
Rails.application.routes.draw do
  mount Flipflop::Engine => "/features"
  mount HealthMonitor::Engine, at: "/"

  resources :mediaflux_info, only: [:index]
  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }

  authenticate :user, ->(user) { user.developer || user.sysadmin } do
    mount Sidekiq::Web => "/sidekiq" # mount Sidekiq::Web in your Rails app
  end

  get "/users-lookup", to: "users#lookup", as: :users_lookup
  resources :users, except: [:new, :destroy, :create] do
    get "/users/:user", action: :index, on: :collection
  end

  devise_scope :user do
    get "sign_in", to: "devise/sessions#new", as: :new_user_session
    get "sign_out", to: "devise/sessions#destroy", as: :destroy_user_session
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root to: "welcome#index"
  get "help", to: "welcome#help", as: :help
  get "dashboard", to: "dashboard#index"
  post "emulate", to: "dashboard#emulate", as: :emulate
  post "dash_project", to: "dashboard#dash_project", as: :dash_project
  post "dash_admin", to: "dashboard#dash_admin", as: :dash_admin

  resources :projects, except: [:new, :edit]
  get "projects/:id/details", to: "projects#details", as: :project_details
  get "projects/:id/list-contents", to: "projects#list_contents", as: :project_list_contents
  get "projects/:id/revision_confirmation", to: "projects#revision_confirmation", as: :project_revision_confirmation
  get "projects/file_list_download/:job_id", to: "projects#file_list_download", as: :project_file_list_download
  get "projects/:id/:id-mf", to: "projects#show_mediaflux", as: :project_show_mediaflux

  resources :requests do
    member do
      get :approve
    end
  end

  get "admin_edit_request/:id", to: "edit_requests#edit", as: :admin_edit_request
  put "admin_edit_request/:id", to: "edit_requests#update"

  namespace :api do
    namespace :v0 do
      resources :projects, only: [:index]
    end
  end

  mount ActionCable.server => "/cable"
  get "mediaflux_extra", to: "users/mediaflux_callbacks#cas", as: :mediaflux_extra
  get "mediaflux_passthru", to: "users/mediaflux_callbacks#passthru", as: :mediaflux_passthru

  put "project_import", to: "project_import#run"
  get "project_import", to: "dashboard#index"

  get "new-project/project-info/(:request_id)", to: "new_project_wizard/project_information#show", as: :new_project_project_info
  put "new-project/project-info/:request_id/save", to: "new_project_wizard/project_information#save", as: :new_project_project_info_save

  get "new-project/project-info-categories/:request_id", to: "new_project_wizard/project_information_categories#show", as: :new_project_project_info_categories
  put "new-project/project-info-categories/:request_id/save", to: "new_project_wizard/project_information_categories#save", as: :new_project_project_info_categories_save

  get "new-project/project-info-dates/:request_id", to: "new_project_wizard/project_information_dates#show", as: :new_project_project_info_dates
  put "new-project/project-info-dates/:request_id/save", to: "new_project_wizard/project_information_dates#save", as: :new_project_project_info_dates_save

  get "new-project/roles-people/:request_id", to: "new_project_wizard/roles_and_people#show", as: :new_project_roles_and_people
  put "new-project/roles-people/:request_id/save", to: "new_project_wizard/roles_and_people#save", as: :new_project_roles_and_people_save

  get "new-project/project-type/:request_id", to: "new_project_wizard/project_type#show", as: :new_project_project_type
  put "new-project/project-type/:request_id/save", to: "new_project_wizard/project_type#save", as: :new_project_project_type_save

  get "new-project/storage-access/:request_id", to: "new_project_wizard/storage_and_access#show", as: :new_project_storage_and_access
  put "new-project/storage-access/:request_id/save", to: "new_project_wizard/storage_and_access#save", as: :new_project_storage_and_access_save

  get "new-project/additional-info-grants-funding/:request_id", to: "new_project_wizard/additional_information_grants_and_funding#show",
                                                                as: :new_project_additional_information_grants_and_funding
  put "new-project/additional-info-grants-funding/:request_id/save", to: "new_project_wizard/additional_information_grants_and_funding#save",
                                                                     as: :new_project_additional_information_grants_and_funding_save

  get "new-project/additional-info-project-permissions/:request_id", to: "new_project_wizard/additional_information_project_permissions#show",
                                                                     as: :new_project_additional_information_project_permissions
  put "new-project/additional-info-project-permissions/:request_id/save", to: "new_project_wizard/additional_information_project_permissions#save",
                                                                          as: :new_project_additional_information_project_permissions_save

  get "new-project/additional-info-related-resources/:request_id", to: "new_project_wizard/additional_information_related_resources#show",
                                                                   as: :new_project_additional_information_related_resources
  put "new-project/additional-info-related-resources/:request_id/save", to: "new_project_wizard/additional_information_related_resources#save",
                                                                        as: :new_project_additional_information_related_resources_save

  get "new-project/review-submit/:request_id", to: "new_project_wizard/review_and_submit#show", as: :new_project_review_and_submit
  put "new-project/review-submit/:request_id/save", to: "new_project_wizard/review_and_submit#save", as: :new_project_review_and_submit_save

  get "request_submit", to: "request_submit#index"

  get "aql_queries", to: "aql_queries#index"

  # Catch any undefined path and render a 404 page not found
  get "*path", to: "application#render_not_found"
end
# rubocop:enable Metrics/BlockLength
