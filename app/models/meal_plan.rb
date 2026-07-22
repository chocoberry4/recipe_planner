class MealPlan < ApplicationRecord
  belongs_to :user
  belongs_to :recipe, optional: true

  enum :meal_type, { breakfast: 0, lunch: 1, dinner: 2, snack: 3 }

  before_validation { self.label = label.to_s.strip.presence }

  validates :date, presence: true
  validates :label, presence: true, if: -> { recipe_id.blank? }
end
