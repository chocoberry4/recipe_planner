module API
  module V1
    class RecipesController < API::ApplicationController
      before_action :find_recipe, only: %i[show update destroy]
      def index
        recipes = Recipe.all
        render json: recipes, each_serializer: RecipeSerializer
      end

      def show
        render json: @recipe, serializer: RecipeSerializer
      end

      def create
        recipe = Recipe.new(recipe_params)
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
        params.require(:recipe).permit(:name, :description, :ingredients, :instructions)
      end

      def find_recipe
        @recipe = Recipe.find(params[:id])
      end
    end
  end
end
