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

  # Shared by every path that can attach a file to `image` - RecipeImagesController
  # (a direct upload) and TandoorImporter (an image bundled in an imported .zip).
  ALLOWED_IMAGE_CONTENT_TYPES = %w[image/jpeg image/png image/webp image/gif].freeze
  MAX_IMAGE_BYTES = 5.megabytes

  # An uploaded/imported image is often a full-resolution photo (seen well
  # over 1MB) - serving that untouched into a 64px list thumbnail or a 384px
  # detail-page hero was the main cause of slow image loads. These two sizes
  # cover every place `image` is actually displayed at (see RecipeSummarySerializer
  # and RecipeSerializer's own image_url); resize_to_fill crops the thumbnail
  # to a clean square (list/picker tiles are both square), resize_to_limit
  # only shrinks the large variant, never upscales a smaller original.
  # Recipe photos are never PNGs/GIFs for a reason worth keeping (transparency,
  # animation) - forcing JPEG output matters as much as the resize itself,
  # since a losslessly-recompressed PNG can end up *larger* than the original
  # even at a smaller size.
  def thumbnail_variant
    image.variant(resize_to_fill: [ 320, 320 ], format: :jpeg, saver: { quality: 80 })
  end

  def large_variant
    image.variant(resize_to_limit: [ 1200, 1200 ], format: :jpeg, saver: { quality: 85 })
  end

  validates :title, presence: true
  validates :description, presence: true
end
