Rails.application.routes.draw do
  root to: "dashboard#index"
  devise_for :users

  # Authenticated dashboard area
  get "dashboard", to: "dashboard#index", as: :dashboard

  scope '/dashboard', as: :dashboard do
    resources :accounts, except: :show
    resources :categories, except: :show do
      resources :categorization_rules, only: [:index, :create, :destroy], module: :categories
    end
    resources :categorization_suggestions
    resources :budget_alerts, only: [:index]
    resources :transactions, except: :show do
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
    resources :investments do
      resources :trades, only: [:index, :create, :edit, :update, :destroy], module: :investments do
        collection do
          delete :clear
        end
      end
      collection do
        get :cards
        post :refresh_all_prices
      end
      member do
        post :refresh_price
      end
    end
    resources :bill_reminders, except: :show
    resources :goals, except: :show do
      member do
        patch :contribute
      end
    end
    resources :debts, except: :show
    resources :budgets
    
    get "reports", to: "dashboard#reports"
    get "simulation", to: "dashboard#simulation"
    get "health", to: "dashboard#health"
    get "news", to: "dashboard#news"
    get "indicators", to: "dashboard#indicators"
    get "settings", to: "dashboard#settings"
    patch "settings", to: "dashboard#update_settings"
    get "backup", to: "dashboard#backup"
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  # PWA routes
  get "/manifest.json" => "pwa#manifest", as: :pwa_manifest
  get "/service-worker.js" => "pwa#service_worker", as: :pwa_service_worker
end
