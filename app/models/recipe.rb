class Recipe < ApplicationRecord
  belongs_to :user
  has_many :instructions, dependent: :destroy
  has_many :recipe_ingredients, dependent: :destroy
  has_many :ingredients, through: :recipe_ingredients
  has_many :recipe_ingredient_groups, dependent: :destroy
  has_many :recipe_tags, dependent: :destroy
  has_many :tags, through: :recipe_tags

  validates :title, presence: true
  validates :description, presence: true
end
