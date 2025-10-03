class CreatePantryItems < ActiveRecord::Migration[8.0]
  def change
    create_table :pantry_items do |t|
      t.references :ingredient, null: false, foreign_key: true
      t.decimal :quantity
      t.string :unit
      t.string :location

      t.timestamps
    end
  end
end
