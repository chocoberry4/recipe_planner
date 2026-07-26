class AddTandoorImportEnabledToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :tandoor_import_enabled, :boolean, default: false, null: false
  end
end
