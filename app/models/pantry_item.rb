class PantryItem < ApplicationRecord
  belongs_to :ingredient

  validates :quantity, numericality: { greater_than_or_equal_to: 0 }
  enum :location, { fridge: 0, freezer: 1, pantry: 2, other: 3 }
end
