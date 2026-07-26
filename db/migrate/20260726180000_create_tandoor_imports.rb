class CreateTandoorImports < ActiveRecord::Migration[8.0]
  def change
    create_table :tandoor_imports do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.integer :total_recipes
      t.integer :processed_recipes, null: false, default: 0
      t.jsonb :recipe_ids, null: false, default: []
      t.jsonb :import_errors, null: false, default: []

      t.timestamps
    end
  end
end
