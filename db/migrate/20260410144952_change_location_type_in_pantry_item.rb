class ChangeLocationTypeInPantryItem < ActiveRecord::Migration[8.0]
  def change
    change_column :pantry_items, :location, :integer, using: 'location::integer'
  end
end
