module Api
  module V1
    class RecipeImportsController < Api::BaseController
      before_action :require_login

      def create
        result = import_params[:url].present? ? import_from_url : import_from_text

        if result.ok?
          recipe = Recipe.includes(RecipeSerializer::EAGER_LOAD).find(result.recipe.id)
          render json: recipe, status: :created, serializer: RecipeSerializer
        else
          render json: { error: result.reason }, status: :unprocessable_entity
        end
      end

      private

      def import_params
        params.permit(:url, :title, :description, :ingredients_text, :instructions_text)
      end

      def import_from_url
        RecipeImporter.from_url(import_params[:url], user: current_user)
      end

      def import_from_text
        RecipeImporter.from_text(
          title: import_params[:title],
          description: import_params[:description],
          ingredients_text: import_params[:ingredients_text],
          instructions_text: import_params[:instructions_text],
          user: current_user
        )
      end
    end
  end
end
