class AddRecipeIngredientGroupToInstructions < ActiveRecord::Migration[8.0]
  def change
    add_reference :instructions, :recipe_ingredient_group, null: true, foreign_key: true
  end
end
