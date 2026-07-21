class CreateTagPins < ActiveRecord::Migration[8.0]
  def change
    create_table :tag_pins do |t|
      t.references :user, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true

      t.timestamps
    end
    add_index :tag_pins, [ :user_id, :tag_id ], unique: true
  end
end
