class CreateIngredients < ActiveRecord::Migration[8.0]
  def change
    create_table :ingredients do |t|
      t.string :name
      t.string :unit_type
      t.string :category

      t.timestamps
    end
    add_index :ingredients, :name, unique: true
  end
end
