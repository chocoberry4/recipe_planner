require 'rails_helper'

RSpec.describe RecipeIngredient, type: :model do
  it "is invalid with a negative quantity" do
    recipe_ingredient = build(:recipe_ingredient, quantity: -1)
    expect(recipe_ingredient).not_to be_valid
  end

  it "is valid with a nil quantity (e.g. a 'to taste' ingredient with no amount)" do
    recipe_ingredient = build(:recipe_ingredient, quantity: nil)
    expect(recipe_ingredient).to be_valid
  end

  it "optionally belongs to a recipe_ingredient_group" do
    recipe_ingredient = build(:recipe_ingredient, recipe_ingredient_group: nil)
    expect(recipe_ingredient).to be_valid
  end

  it "can belong to a recipe_ingredient_group on the same recipe" do
    recipe = create(:recipe)
    group = create(:recipe_ingredient_group, recipe: recipe)
    recipe_ingredient = create(:recipe_ingredient, recipe: recipe, recipe_ingredient_group: group)

    expect(recipe_ingredient.recipe_ingredient_group).to eq(group)
  end

  it "supports a preparation separate from the ingredient's canonical name" do
    recipe_ingredient = create(:recipe_ingredient, preparation: "minced")

    expect(recipe_ingredient.preparation).to eq("minced")
    expect(recipe_ingredient.ingredient.name).not_to include("minced")
  end
end
