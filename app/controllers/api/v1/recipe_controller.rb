class API::V1::RecipeController < API::ApplicationController

  def index
    recipes = Recipe.all
    render json: recipes, each_serializer: API::V1::RecipeSerializer
end
