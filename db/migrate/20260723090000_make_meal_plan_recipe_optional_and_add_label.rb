class MakeMealPlanRecipeOptionalAndAddLabel < ActiveRecord::Migration[8.0]
  def change
    change_column_null :meal_plans, :recipe_id, true
    add_column :meal_plans, :label, :string
  end
end
