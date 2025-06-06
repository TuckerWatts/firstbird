require 'sidekiq/web'

Rails.application.routes.draw do
  mount Sidekiq::Web => '/sidekiq'

  devise_for :users
  
  root 'stocks#index'

  resources :stocks do
    collection do
      post :refresh_top_stocks
      get :day_details
      get :historical_data
      get :top_stocks
      get :desired_stocks
      get :stock_predictions
    end

    member do
      post :refresh_data
    end
  end

  namespace :admin do
    get 'fetch_data', to: 'data#fetch_data'
  end

  post 'fetch_data', to: 'data#fetch_data', as: 'fetch_data'
end
