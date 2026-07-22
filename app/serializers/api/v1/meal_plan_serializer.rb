module Api
  module V1
    class MealPlanSerializer < ActiveModel::Serializer
      attributes :id, :date, :meal_type, :position, :label, :recipe

      def recipe
        return nil unless object.recipe

        {
          id: object.recipe.id,
          title: object.recipe.title,
          image_url: object.recipe.image_url,
          duration_minutes: object.recipe.duration_minutes
        }
      end
    end
  end
end
