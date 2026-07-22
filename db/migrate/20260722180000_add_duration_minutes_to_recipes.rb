class AddDurationMinutesToRecipes < ActiveRecord::Migration[8.0]
  def change
    add_column :recipes, :duration_minutes, :integer
  end
end
