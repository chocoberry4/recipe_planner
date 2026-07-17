class Instruction < ApplicationRecord
  belongs_to :recipe
  belongs_to :recipe_ingredient_group, optional: true
  has_many :instruction_ingredients, dependent: :destroy
  has_many :recipe_ingredients, through: :instruction_ingredients

  validates :description, presence: true
end
