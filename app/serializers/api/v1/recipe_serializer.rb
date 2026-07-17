module Api
  module V1
    class RecipeSerializer < ActiveModel::Serializer
      # Ingredients are split across two attributes:
      # - `recipe_ingredient_groups`: sectioned ingredients (e.g. "Marinade"),
      #   each carrying its own ordered `recipe_ingredients`.
      # - `ingredients`: ungrouped recipe_ingredients (recipe_ingredient_group_id IS NULL).
      # Both shapes serialize each recipe_ingredient the same way (via
      # `recipe_ingredient_json`), including `preparation` split out of the
      # ingredient name so later matching logic can key off the clean name.
      attributes :id, :title, :description, :user_id, :recipe_ingredient_groups,
                 :ingredients, :instructions, :created_at, :updated_at

      def recipe_ingredient_groups
        object.recipe_ingredient_groups.order(:position).map do |group|
          {
            id: group.id,
            name: group.name,
            position: group.position,
            recipe_ingredients: group.recipe_ingredients.order(:position).map { |ri| recipe_ingredient_json(ri) }
          }
        end
      end

      def ingredients
        object.recipe_ingredients.where(recipe_ingredient_group_id: nil).order(:position).map do |ri|
          recipe_ingredient_json(ri)
        end
      end

      def instructions
        object.instructions.order(:step_number).map do |instruction|
          {
            id: instruction.id,
            step_number: instruction.step_number,
            description: instruction.description,
            duration_minutes: instruction.duration_minutes,
            recipe_ingredient_group_id: instruction.recipe_ingredient_group_id
          }
        end
      end

      private

      def recipe_ingredient_json(recipe_ingredient)
        {
          id: recipe_ingredient.id,
          ingredient_id: recipe_ingredient.ingredient_id,
          name: recipe_ingredient.ingredient.name,
          quantity: recipe_ingredient.quantity,
          unit: recipe_ingredient.unit,
          preparation: recipe_ingredient.preparation,
          position: recipe_ingredient.position
        }
      end
    end
  end
end
