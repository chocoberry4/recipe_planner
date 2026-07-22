class AddImageUrlToInstructions < ActiveRecord::Migration[8.0]
  def change
    add_column :instructions, :image_url, :string
  end
end
