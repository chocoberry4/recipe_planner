class Recipe < ApplicationController
  belongs_to :user
  validates :title, presence: true
  # validates :ingredients, presence: true
  # validates :instructions, presence: true
end