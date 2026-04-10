Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :users
      resources :recipes
      resources :ingredients

      post "login", to: "auth#login"
      post "signup", to: "auth#signup"
      delete "logout", to: "auth#logout"
    end
  end
end
