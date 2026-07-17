require 'rails_helper'

RSpec.describe InstructionIngredient, type: :model do
  it "belongs to an instruction and a recipe_ingredient" do
    instruction_ingredient = create(:instruction_ingredient)

    expect(instruction_ingredient.instruction).to be_present
    expect(instruction_ingredient.recipe_ingredient).to be_present
  end

  it "is invalid without an instruction" do
    instruction_ingredient = build(:instruction_ingredient, instruction: nil)
    expect(instruction_ingredient).not_to be_valid
  end

  it "is invalid without a recipe_ingredient" do
    instruction_ingredient = build(:instruction_ingredient, recipe_ingredient: nil)
    expect(instruction_ingredient).not_to be_valid
  end
end
