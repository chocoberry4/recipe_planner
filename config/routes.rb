Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :users
      resources :recipes do
        resource :instruction_ingredients, only: :update
        resources :image_candidates, only: :index, controller: "recipe_image_candidates"
        resource :image, only: %i[create destroy], controller: "recipe_images"
      end
      resources :ingredients
      resources :meal_plans, only: %i[index create update destroy]
      resource :pinned_tags, only: %i[show update]
      resource :user_preferences, only: %i[show update]
      resources :tandoor_imports, only: %i[create show]

      post "recipes/import", to: "recipe_imports#create"

      post "login", to: "auth#login"
      post "signup", to: "auth#signup"
      delete "logout", to: "auth#logout"
      get "me", to: "auth#me"
    end
  end

  root "pages#index"
  # Vue Router uses history mode, so any non-API path must serve the same
  # SPA shell and let the client-side router take over. Rails auto-mounts
  # engine routes (ActiveStorage's blob/representation URLs among them)
  # *after* this file's own routes, so an unconstrained catch-all here would
  # swallow requests meant for them - e.g. a recipe's uploaded-image URL
  # (/rails/active_storage/blobs/...) would 406 by hitting PagesController
  # instead. Excluding /rails/ keeps every such engine reachable.
  get "*path", to: "pages#index", constraints: ->(req) { !req.path.start_with?("/api/", "/rails/") }
end
