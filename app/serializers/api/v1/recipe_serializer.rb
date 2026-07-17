module Api
  module V1
    class RecipeSerializer < ActiveModel::Serializer
      attributes :id, :title, :description, :ingredients,
                 :instructions, :created_at, :updated_at
    end
  end
end
