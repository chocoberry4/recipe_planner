class AddPlannerPreferencesToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :show_breakfast, :boolean, null: false, default: true
    add_column :users, :show_lunch, :boolean, null: false, default: true
    add_column :users, :show_dinner, :boolean, null: false, default: true
    add_column :users, :show_snack, :boolean, null: false, default: true
    add_column :users, :home_view, :integer, null: false, default: 0
  end
end
