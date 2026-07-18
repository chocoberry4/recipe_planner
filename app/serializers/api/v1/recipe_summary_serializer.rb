module Api
  module V1
    # Used by RecipesController#index - the recipe list view (Recipes.vue)
    # only ever reads title/description, but the full RecipeSerializer pulls
    # every ingredient/group/instruction for every recipe on the page, which
    # is both wasted payload and (before EAGER_LOAD existed) an N+1 query
    # storm. Nothing here touches an association, so this needs no includes.
    class RecipeSummarySerializer < ActiveModel::Serializer
      attributes :id, :title, :description, :user_id, :created_at, :updated_at
    end
  end
end
