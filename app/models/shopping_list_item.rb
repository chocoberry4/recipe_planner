class ShoppingListItem < ApplicationRecord
  belongs_to :shopping_list
  belongs_to :ingredient

  validates :quantity, numericality: { greater_than_or_equal_to: 0 }
end
