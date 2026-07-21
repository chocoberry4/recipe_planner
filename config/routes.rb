Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :users
      resources :recipes do
        resource :instruction_ingredients, only: :update
        resources :image_candidates, only: :index, controller: "recipe_image_candidates"
      end
      resources :ingredients
      resource :pinned_tags, only: %i[show update]

      post "recipes/import", to: "recipe_imports#create"

      post "login", to: "auth#login"
      post "signup", to: "auth#signup"
      delete "logout", to: "auth#logout"
      get "me", to: "auth#me"
    end
  end

  root "pages#index"
  # Vue Router uses history mode, so any non-API path must serve the same
  # SPA shell and let the client-side router take over.
  get "*path", to: "pages#index", constraints: ->(req) { !req.path.start_with?("/api/") }
end
