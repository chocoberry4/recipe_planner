class CreateRecipeIngredientGroups < ActiveRecord::Migration[8.0]
  def change
    create_table :recipe_ingredient_groups do |t|
      t.references :recipe, null: false, foreign_key: true
      t.string :name
      t.integer :position

      t.timestamps
    end
  end
end
