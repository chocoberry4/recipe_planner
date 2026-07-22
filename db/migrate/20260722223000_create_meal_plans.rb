class CreateMealPlans < ActiveRecord::Migration[8.0]
  def change
    create_table :meal_plans do |t|
      t.references :user, null: false, foreign_key: true
      t.references :recipe, null: false, foreign_key: true
      t.date :date, null: false
      t.integer :meal_type, null: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end
    add_index :meal_plans, [ :user_id, :date ]
    add_index :meal_plans, [ :user_id, :date, :meal_type ]
  end
end
