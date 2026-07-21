class Tag < ApplicationRecord
  has_many :recipe_tags, dependent: :destroy
  has_many :recipes, through: :recipe_tags

  # Normalized to lowercase so "Dessert" and "dessert" resolve to the same
  # tag rather than silently creating near-duplicates - unlike Ingredient
  # names, tags are meant to be used for consistent filtering/categorization.
  before_validation { self.name = name.to_s.strip.downcase }

  validates :name, presence: true, uniqueness: true
end
