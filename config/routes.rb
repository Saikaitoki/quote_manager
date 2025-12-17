Rails.application.routes.draw do


  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  resources :quotes do
    collection do
      post :sync_from_kintone
    end

    resources :items, only: [ :create, :destroy ]
  end

  namespace :kintone do
    get "products/lookup", to: "products#lookup"
    get "customers/lookup", to: "customers#lookup"
    get "staffs/lookup",    to: "staffs#lookup"
  end

  root "quotes#index"
end
