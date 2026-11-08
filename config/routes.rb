Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "products#index"
  resources :products, only: :index
  resources :orders, only: :index
end
