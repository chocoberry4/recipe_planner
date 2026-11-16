class CreateShoppingItems < ActiveRecord::Migration[8.0]
  def change
    create_table :shopping_items do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.decimal :quantity
      t.string :unit
      t.boolean :checked, null: false, default: false

      t.timestamps
    end
  end
end
