module Api
  module V1
    class RecipesController < Api::BaseController
      # Recipe browsing (index/show) stays public; mutating a recipe requires
      # a logged-in user since recipes belong to one (see Recipe#user).
      before_action :require_login, only: %i[create update destroy]
      before_action :find_recipe, only: %i[show update destroy]
      before_action :require_owner, only: %i[update destroy]

      def index
        recipes = Recipe.all
        render json: recipes, each_serializer: RecipeSerializer
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
          render json: result.recipe, status: :ok, serializer: RecipeSerializer
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
        @recipe = Recipe.find(params[:id])
      end

      def require_owner
        return if @recipe.user_id == current_user.id

        render json: { error: "Not authorized" }, status: :forbidden
      end
    end
  end
end
