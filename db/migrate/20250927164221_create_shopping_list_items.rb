class CreateShoppingListItems < ActiveRecord::Migration[8.0]
  def change
    create_table :shopping_list_items do |t|
      t.references :shopping_list, null: false, foreign_key: true
      t.references :ingredient, null: false, foreign_key: true
      t.decimal :quantity
      t.string :unit
      t.boolean :is_checked

      t.timestamps
    end
  end
end
