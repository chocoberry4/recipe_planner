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
        recipe = current_user.recipes.build(recipe_params)
        if recipe.save
          render json: recipe, status: :created, serializer: RecipeSerializer
        else
          render json: { errors: recipe.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @recipe.update(recipe_params)
          render json: @recipe, status: :ok, serializer: RecipeSerializer
        else
          render json: { errors: @recipe.errors.full_messages }, status: :unprocessable_entity
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

      def recipe_params
        # Owner is set from current_user (see #create), not a client-supplied
        # param. Nested ingredients/instructions have no accepts_nested_attributes_for
        # setup yet, so they aren't accepted here — that's Unit 02 Slice B / import.
        params.require(:recipe).permit(:title, :description)
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
