class CreateInstructionIngredients < ActiveRecord::Migration[8.0]
  def change
    create_table :instruction_ingredients do |t|
      t.references :instruction, null: false, foreign_key: true
      t.references :recipe_ingredient, null: false, foreign_key: true

      t.timestamps
    end
  end
end
