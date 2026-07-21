module Api
  module V1
    # Re-derives a recipe's candidate cover images from its source page, for
    # the review UI's image picker. Nothing is persisted here - selecting one
    # goes through RecipesController#update (:image_url), same as any other
    # recipe field edit.
    class RecipeImageCandidatesController < Api::BaseController
      before_action :require_login

      def index
        recipe = current_user.recipes.find(params[:recipe_id])
        render json: { image_urls: RecipeImporter.image_candidates_for(recipe.source_url) }
      end
    end
  end
end
