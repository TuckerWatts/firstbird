Rails.application.routes.draw do
  root 'stocks#index'

  devise_for :users

  resources :stocks, only: [:index, :show]

  post 'fetch_data', to: 'data#fetch_data', as: 'fetch_data'
end
