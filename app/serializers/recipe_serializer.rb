module API
  module V1
    class RecipeSerializer < ActiveModel::Serializer
      attributes :id, :name, :description, :ingredients,
                 :instructions, :created_at, :updated_at
    end
  end
end
