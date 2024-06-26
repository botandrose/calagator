# frozen_string_literal: true

Calagator::Engine.routes.draw do
  # Not sure why, but routes is getting loaded twice. This ignores the second load.
  return unless Calagator::Engine.routes.empty?

  root "site#index"

  get "omfg" => "site#omfg"
  get "hello" => "site#hello"

  get "about" => "site#about"

  get "opensearch.:format" => "site#opensearch"
  get "defunct" => "site#defunct"

  get "admin" => "admin#index"
  get "admin/index"
  get "admin/events"
  post "lock_event" => "admin#lock_event"

  resources :events do
    collection do
      post :squash_many_duplicates
      get :search
      get :duplicates
      get "tag/:tag", action: :search, as: :tag
    end

    member do
      get :clone
    end
  end

  resources :sources do
    post :import, on: :collection
    patch :reimport, on: :member
  end

  resources :venues do
    collection do
      post :squash_many_duplicates
      get :map
      get :duplicates
      get :autocomplete
      get "tag/:tag", action: :index, as: :tag
    end
  end

  resources :versions, only: [:edit]
  resources :changes, controller: "/paper_trail_manager/changes"

  get "recent_changes" => redirect("/changes")
  get "recent_changes.:format" => redirect("/changes.%{format}")

  get "css/:name" => "site#style"
  get "css/:name.:format" => "site#style"

  get "/index" => "site#index"
  get "/index.:format" => "site#index"
end