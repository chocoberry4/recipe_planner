class AddGroupingFieldsToRecipeIngredients < ActiveRecord::Migration[8.0]
  def change
    add_reference :recipe_ingredients, :recipe_ingredient_group, null: true, foreign_key: true
    add_column :recipe_ingredients, :preparation, :string
    add_column :recipe_ingredients, :position, :integer
  end
end
