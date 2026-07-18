class RecipeIngredient < ApplicationRecord
  belongs_to :recipe
  belongs_to :ingredient
  belongs_to :recipe_ingredient_group, optional: true
  has_many :instruction_ingredients, dependent: :destroy

  validates :quantity, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
end
