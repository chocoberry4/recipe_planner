class User < ApplicationRecord
  has_secure_password
  validates :email, presence: true, uniqueness: true
  validates :password, presence: true, length: { minimum: 6 }, on: :create
  has_many :recipes
  has_many :shopping_lists
  has_many :tag_pins, dependent: :destroy
  has_many :pinned_tags, through: :tag_pins, source: :tag
end
