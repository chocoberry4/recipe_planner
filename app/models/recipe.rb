class Recipe < ApplicationRecord
  belongs_to :user
  has_many :instructions, dependent: :destroy
  has_many :recipe_ingredients, dependent: :destroy
  has_many :ingredients, through: :recipe_ingredients
  has_many :recipe_ingredient_groups, dependent: :destroy
  has_many :recipe_tags, dependent: :destroy
  has_many :tags, through: :recipe_tags
  has_many :meal_plans, dependent: :destroy

  # An uploaded file (via RecipeImagesController) and the pasted-URL
  # `image_url` column are two ways to set the same cover image, never both
  # at once - see RecipeSerializer#image_url for which one wins, and
  # RecipeUpdater/RecipeImagesController for how setting one clears the other.
  has_one_attached :image

  validates :title, presence: true
  validates :description, presence: true
end
