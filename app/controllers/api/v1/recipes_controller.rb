module Api
  module V1
    class RecipesController < Api::BaseController
      # Recipes are private to their owner - no public/shared visibility yet
      # (a future "public" recipe setting is planned but out of scope for
      # now), so every action here requires login and is scoped to
      # current_user.recipes. A recipe id that exists but belongs to someone
      # else 404s the same as one that doesn't exist at all, rather than
      # revealing its existence via a 403.
      before_action :require_login
      before_action :find_recipe, only: %i[show update destroy]

      def index
        render json: current_user.recipes, each_serializer: RecipeSummarySerializer
      end

      def show
        render json: @recipe, serializer: RecipeSerializer
      end

      def create
        recipe = current_user.recipes.build(create_params)
        if recipe.save
          render json: recipe, status: :created, serializer: RecipeSerializer
        else
          render json: { errors: recipe.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        result = RecipeUpdater.call(@recipe, update_params)
        if result.ok?
          render json: reload_for_serialization(result.recipe), status: :ok, serializer: RecipeSerializer
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      end

      def destroy
        if @recipe.destroy
          head :no_content
        else
          render json: { errors: @recipe.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def create_params
        # Owner is set from current_user, not a client-supplied param. No
        # nested ingredients/instructions here - a freshly-built recipe has no
        # associations to attach them to yet (see RecipeImporter for the
        # from-scratch creation path, which does support them).
        params.require(:recipe).permit(:title, :description)
      end

      def update_params
        # Nested writes go through RecipeUpdater rather than
        # accepts_nested_attributes_for, since renaming an ingredient needs to
        # re-resolve it via Ingredient.find_or_create_by (see RecipeUpdater),
        # not mutate the shared Ingredient row in place.
        params.require(:recipe).permit(
          :title, :description,
          recipe_ingredient_groups: [
            :id, :name, :position, :_destroy,
            recipe_ingredients: [ :id, :name, :quantity, :unit, :preparation, :position, :_destroy ]
          ],
          ingredients: [ :id, :name, :quantity, :unit, :preparation, :position, :_destroy ],
          instructions: [ :id, :description, :step_number, :recipe_ingredient_group_id, :_destroy ]
        )
      end

      def find_recipe
        @recipe = current_user.recipes.includes(RecipeSerializer::EAGER_LOAD).find(params[:id])
      end

      def reload_for_serialization(recipe)
        current_user.recipes.includes(RecipeSerializer::EAGER_LOAD).find(recipe.id)
      end
    end
  end
end
