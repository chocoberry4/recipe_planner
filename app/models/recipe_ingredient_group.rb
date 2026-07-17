class RecipeIngredientGroup < ApplicationRecord
  belongs_to :recipe
  has_many :recipe_ingredients, dependent: :nullify
  has_many :instructions, dependent: :nullify

  validates :name, presence: true
end
