class AddServingsToRecipes < ActiveRecord::Migration[8.0]
  def change
    add_column :recipes, :servings, :integer
  end
end
