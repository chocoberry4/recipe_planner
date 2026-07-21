module Api
  module V1
    # Used by RecipesController#index - the recipe list view (Recipes.vue)
    # only ever reads title/description/tags, but the full RecipeSerializer
    # pulls every ingredient/group/instruction for every recipe on the page,
    # which is both wasted payload and (before EAGER_LOAD existed) an N+1
    # query storm. `tags` is the only association touched here - the
    # controller must `.includes(:tags)` or this reintroduces an N+1.
    class RecipeSummarySerializer < ActiveModel::Serializer
      attributes :id, :title, :description, :image_url, :user_id, :tags, :created_at, :updated_at

      def tags
        object.tags.sort_by(&:name).map { |tag| { id: tag.id, name: tag.name } }
      end
    end
  end
end
