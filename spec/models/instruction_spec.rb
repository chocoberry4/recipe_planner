require 'rails_helper'

RSpec.describe Instruction, type: :model do
  it "is invalid without a description" do
    instruction = build(:instruction, description: nil)
    expect(instruction).not_to be_valid
  end

  it "optionally belongs to a recipe_ingredient_group" do
    instruction = build(:instruction, recipe_ingredient_group: nil)
    expect(instruction).to be_valid
  end

  it "can belong to a recipe_ingredient_group" do
    recipe = create(:recipe)
    group = create(:recipe_ingredient_group, recipe: recipe)
    instruction = create(:instruction, recipe: recipe, recipe_ingredient_group: group)

    expect(instruction.recipe_ingredient_group).to eq(group)
  end

  it "associates recipe_ingredients through instruction_ingredients" do
    recipe = create(:recipe)
    instruction = create(:instruction, recipe: recipe)
    recipe_ingredient = create(:recipe_ingredient, recipe: recipe)
    create(:instruction_ingredient, instruction: instruction, recipe_ingredient: recipe_ingredient)

    expect(instruction.recipe_ingredients).to contain_exactly(recipe_ingredient)
  end

  it "destroys its instruction_ingredients when destroyed" do
    recipe = create(:recipe)
    instruction = create(:instruction, recipe: recipe)
    recipe_ingredient = create(:recipe_ingredient, recipe: recipe)
    instruction_ingredient = create(:instruction_ingredient, instruction: instruction, recipe_ingredient: recipe_ingredient)

    instruction.destroy

    expect(InstructionIngredient.exists?(instruction_ingredient.id)).to be false
  end
end
