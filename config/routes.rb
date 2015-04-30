Rails.application.routes.draw do

  root to: 'devices#index'

  resources :devices, only: [:index]
  get 'devices/:device', to: 'devices#show'
  patch 'devices/:device', to: 'devices#update'
  
end
