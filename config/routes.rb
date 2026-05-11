Rails.application.routes.draw do
  root to: "home#index"
  devise_for :users

  # Authenticated dashboard area
  get "dashboard", to: "dashboard#index", as: :dashboard

  scope as: :dashboard do
    resources :accounts
    resources :categories do
      resources :categorization_rules, only: [:create, :destroy], module: :categories
    end
    resources :transactions do
      collection do
        get :import
        post :do_import
      end
    end
    resources :notifications, only: [:index, :update] do
      collection do
        post :mark_all_as_read
      end
    end
    resources :investments
    resources :goals do
      member do
        patch :contribute
      end
    end
    resources :debts
    resources :budgets
    
    get "reports", to: "dashboard#reports"
    get "simulation", to: "dashboard#simulation"
    get "settings", to: "dashboard#settings"
    patch "settings", to: "dashboard#update_settings"
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  # PWA routes
  get "/manifest.json" => "pwa#manifest", as: :pwa_manifest
  get "/service-worker.js" => "pwa#service_worker", as: :pwa_service_worker
end
