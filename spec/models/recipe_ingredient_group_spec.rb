require 'rails_helper'

RSpec.describe RecipeIngredientGroup, type: :model do
  it "is valid with a recipe and a name" do
    group = build(:recipe_ingredient_group)
    expect(group).to be_valid
  end

  it "is invalid without a name" do
    group = build(:recipe_ingredient_group, name: nil)
    expect(group).not_to be_valid
  end

  it "belongs to a recipe" do
    recipe = create(:recipe)
    group = create(:recipe_ingredient_group, recipe: recipe)

    expect(group.recipe).to eq(recipe)
  end

  it "is destroyed when its recipe is destroyed" do
    recipe = create(:recipe)
    group = create(:recipe_ingredient_group, recipe: recipe)

    recipe.destroy

    expect(RecipeIngredientGroup.exists?(group.id)).to be false
  end

  it "nullifies its recipe_ingredients' group reference when destroyed" do
    group = create(:recipe_ingredient_group)
    recipe_ingredient = create(:recipe_ingredient, recipe: group.recipe, recipe_ingredient_group: group)

    group.destroy

    expect(recipe_ingredient.reload.recipe_ingredient_group_id).to be_nil
  end

  it "nullifies its instructions' group reference when destroyed" do
    group = create(:recipe_ingredient_group)
    instruction = create(:instruction, recipe: group.recipe, recipe_ingredient_group: group)

    group.destroy

    expect(instruction.reload.recipe_ingredient_group_id).to be_nil
  end
end
