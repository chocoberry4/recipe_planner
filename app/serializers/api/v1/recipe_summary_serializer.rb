module Api
  module V1
    # Used by RecipesController#index - the recipe list view (Recipes.vue)
    # only ever reads title/description/tags, but the full RecipeSerializer
    # pulls every ingredient/group/instruction for every recipe on the page,
    # which is both wasted payload and (before EAGER_LOAD existed) an N+1
    # query storm. `tags` and the image attachment are the only associations
    # touched here - the controller must `.includes(:tags, image_attachment: :blob)`
    # or this reintroduces an N+1.
    class RecipeSummarySerializer < ActiveModel::Serializer
      attributes :id, :title, :description, :image_url, :user_id, :duration_minutes, :tags, :created_at, :updated_at

      # An uploaded file (Recipe#image) wins over the pasted-URL column
      # whenever one is attached - see Recipe's has_one_attached comment.
      def image_url
        return Rails.application.routes.url_helpers.rails_blob_path(object.image, only_path: true) if object.image.attached?

        object.image_url
      end

      def tags
        object.tags.sort_by(&:name).map { |tag| { id: tag.id, name: tag.name } }
      end
    end
  end
end
