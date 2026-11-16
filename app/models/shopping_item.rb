# One line on a user's shopping list - free-typed or added from a recipe's
# ingredients. Deliberately independent of Ingredient/RecipeIngredient so an
# item can be anything ("kitchen roll") and survives its source recipe being
# deleted. (The older ShoppingList/ShoppingListItem tables are an unused,
# ingredient-id-based design that doesn't fit that.)
class ShoppingItem < ApplicationRecord
  belongs_to :user

  before_validation do
    self.name = name.to_s.squish
    self.unit = unit.to_s.strip.presence
  end

  validates :name, presence: true, length: { maximum: 200 }
  validates :quantity, numericality: { greater_than: 0 }, allow_nil: true
end
