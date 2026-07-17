require 'rails_helper'

RSpec.describe RecipeAutosorter do
  def assigned_ingredient_ids(instruction)
    instruction.reload.recipe_ingredients.pluck(:id)
  end

  describe "Tier 0: structural alignment" do
    it "assigns every ingredient in a structurally-linked group to its instruction" do
      recipe = create(:recipe)
      group = create(:recipe_ingredient_group, recipe: recipe, name: "Marinade")
      ri1 = create(:recipe_ingredient, recipe: recipe, recipe_ingredient_group: group)
      ri2 = create(:recipe_ingredient, recipe: recipe, recipe_ingredient_group: group)
      instruction = create(:instruction, recipe: recipe, recipe_ingredient_group: group, description: "Combine the section ingredients.")

      described_class.call(recipe)

      expect(assigned_ingredient_ids(instruction)).to contain_exactly(ri1.id, ri2.id)
    end
  end

  describe "Tier 1: group name mentioned in prose" do
    it "assigns a whole group to a step that names it, with no structural link" do
      recipe = create(:recipe)
      group = create(:recipe_ingredient_group, recipe: recipe, name: "Marinade")
      ri1 = create(:recipe_ingredient, recipe: recipe, recipe_ingredient_group: group)
      ri2 = create(:recipe_ingredient, recipe: recipe, recipe_ingredient_group: group)
      instruction = create(:instruction, recipe: recipe, description: "Whisk together the marinade ingredients.")

      described_class.call(recipe)

      expect(assigned_ingredient_ids(instruction)).to contain_exactly(ri1.id, ri2.id)
    end
  end

  describe "Tier 2: individual fuzzy match" do
    it "matches despite reordered phrasing (fixes exact-substring failure mode)" do
      recipe = create(:recipe)
      tomato = create(:ingredient, name: "tomato")
      ri = create(:recipe_ingredient, recipe: recipe, ingredient: tomato, preparation: "diced")
      instruction = create(:instruction, recipe: recipe, description: "Add the diced tomatoes to the pot.")

      described_class.call(recipe)

      expect(assigned_ingredient_ids(instruction)).to contain_exactly(ri.id)
    end

    it "disambiguates duplicate occurrences of the same ingredient by restated quantity" do
      recipe = create(:recipe)
      soy_sauce = create(:ingredient, name: "soy sauce")
      marinade_portion = create(:recipe_ingredient, recipe: recipe, ingredient: soy_sauce, quantity: 2, unit: "tbsp", position: 1)
      glaze_portion = create(:recipe_ingredient, recipe: recipe, ingredient: soy_sauce, quantity: 1, unit: "tbsp", position: 2)
      marinade_step = create(:instruction, recipe: recipe, step_number: 1, description: "Whisk 2 tbsp of the soy sauce with garlic for the marinade.")
      glaze_step = create(:instruction, recipe: recipe, step_number: 2, description: "Stir in the remaining 1 tbsp soy sauce for the glaze.")

      described_class.call(recipe)

      expect(assigned_ingredient_ids(marinade_step)).to contain_exactly(marinade_portion.id)
      expect(assigned_ingredient_ids(glaze_step)).to contain_exactly(glaze_portion.id)
    end

    it "falls back to list order when no quantity is restated" do
      recipe = create(:recipe)
      soy_sauce = create(:ingredient, name: "soy sauce")
      first_portion = create(:recipe_ingredient, recipe: recipe, ingredient: soy_sauce, quantity: 2, unit: "tbsp", position: 1)
      create(:recipe_ingredient, recipe: recipe, ingredient: soy_sauce, quantity: 1, unit: "tbsp", position: 2)
      instruction = create(:instruction, recipe: recipe, description: "Add the soy sauce.")

      described_class.call(recipe)

      expect(assigned_ingredient_ids(instruction)).to contain_exactly(first_portion.id)
    end
  end

  describe "Tier 3: unresolved" do
    it "leaves an ingredient unmentioned in any step unassigned rather than guessing" do
      recipe = create(:recipe)
      salt = create(:ingredient, name: "salt")
      create(:recipe_ingredient, recipe: recipe, ingredient: salt)
      instruction = create(:instruction, recipe: recipe, description: "Preheat the oven to 400 degrees.")

      described_class.call(recipe)

      expect(assigned_ingredient_ids(instruction)).to be_empty
      expect(InstructionIngredient.count).to eq(0)
    end
  end
end
