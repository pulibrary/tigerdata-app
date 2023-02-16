# frozen_string_literal: true
Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root to: "welcome#index"

  namespace :api do
    namespace :v0 do  
      resources :projects, only: [:index]
    end
  end
  
end
