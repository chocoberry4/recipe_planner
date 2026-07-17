class RecipeIngredient < ApplicationRecord
  belongs_to :recipe
  belongs_to :ingredient
  belongs_to :recipe_ingredient_group, optional: true

  validates :quantity, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
end
