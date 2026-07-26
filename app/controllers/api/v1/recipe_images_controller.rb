module Api
  module V1
    # Handles the "upload a file" half of a recipe's cover image (the
    # "paste a URL" half just goes through RecipesController#update's
    # existing :image_url param). Attaching a file here always clears the
    # pasted-URL column, and pasting a URL always purges any attached file
    # (see RecipeUpdater) - exactly one of the two is ever the active
    # source, per RecipeSerializer#image_url.
    class RecipeImagesController < Api::BaseController
      before_action :require_login

      ALLOWED_CONTENT_TYPES = %w[image/jpeg image/png image/webp image/gif].freeze
      MAX_BYTES = 5.megabytes

      def create
        recipe = current_user.recipes.find(params[:recipe_id])
        file = params[:image]

        if file.blank? || !file.respond_to?(:content_type)
          return render json: { errors: [ "No image file was uploaded" ] }, status: :unprocessable_entity
        end

        unless ALLOWED_CONTENT_TYPES.include?(file.content_type)
          return render json: { errors: [ "Image must be a JPEG, PNG, WEBP, or GIF" ] }, status: :unprocessable_entity
        end

        if file.size > MAX_BYTES
          return render json: { errors: [ "Image must be smaller than 5MB" ] }, status: :unprocessable_entity
        end

        recipe.image.attach(file)
        recipe.update!(image_url: nil)
        render json: reload_for_serialization(recipe), serializer: RecipeSerializer
      end

      def destroy
        recipe = current_user.recipes.find(params[:recipe_id])
        recipe.image.purge if recipe.image.attached?
        recipe.update!(image_url: nil)
        render json: reload_for_serialization(recipe), serializer: RecipeSerializer
      end

      private

      def reload_for_serialization(recipe)
        current_user.recipes.includes(RecipeSerializer::EAGER_LOAD).find(recipe.id)
      end
    end
  end
end
