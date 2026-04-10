class Ingredient < ApplicationRecord
  has_many :recipe_ingredients, dependent: :restrict_with_error
  has_many :recipes, through: :recipe_ingredients
  has_many :pantry_items, dependent: :restrict_with_error
  has_many :shopping_list_items, dependent: :restrict_with_error

  validates :name, presence: true
end