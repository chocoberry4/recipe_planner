class InstructionIngredient < ApplicationRecord
  belongs_to :instruction
  belongs_to :recipe_ingredient
end
