Rails.application.routes.draw do
  devise_for :users

  root 'stocks#index'

  resources :stocks, only: [:index, :show]
  
end
