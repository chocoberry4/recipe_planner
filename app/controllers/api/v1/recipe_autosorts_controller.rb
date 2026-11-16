module Api
  module V1
    # Re-runs RecipeAutosorter over a recipe's *current* steps and ingredients,
    # replacing whatever step-ingredient assignments exist. For when steps have
    # been split/merged/reworded and the old assignments no longer line up -
    # the autosorter is the same one import uses, so results match what a fresh
    # import of the same text would give.
    class RecipeAutosortsController < Api::BaseController
      before_action :require_login
      before_action :find_recipe

      def create
        ActiveRecord::Base.transaction do
          InstructionIngredient.where(instruction_id: @recipe.instructions.select(:id)).delete_all
          RecipeAutosorter.call(@recipe)
        end

        render json: Recipe.includes(RecipeSerializer::EAGER_LOAD).find(@recipe.id), serializer: RecipeSerializer
      end

      private

      # Someone else's recipe 404s rather than 403s, same as RecipesController.
      def find_recipe
        @recipe = current_user.recipes.find(params[:recipe_id])
      end
    end
  end
end
