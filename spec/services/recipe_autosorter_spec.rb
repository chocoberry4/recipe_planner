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

    it "matches when the step drops a modifier word from the ingredient's name" do
      recipe = create(:recipe)
      dark_soy = create(:recipe_ingredient, recipe: recipe, ingredient: create(:ingredient, name: "dark soy sauce"))
      instruction = create(:instruction, recipe: recipe, description: "Stir in the soy sauce and simmer.")

      described_class.call(recipe)

      expect(assigned_ingredient_ids(instruction)).to contain_exactly(dark_soy.id)
    end

    it "requires the head noun even when a modifier is droppable" do
      recipe = create(:recipe)
      create(:recipe_ingredient, recipe: recipe, ingredient: create(:ingredient, name: "soy sauce"))
      instruction = create(:instruction, recipe: recipe, description: "Pour in a splash of soy milk.")

      described_class.call(recipe)

      expect(assigned_ingredient_ids(instruction)).to be_empty
    end

    it "does not let a partial match steal a step from a fully-matching ingredient with the same head noun" do
      recipe = create(:recipe)
      baking_powder = create(:recipe_ingredient, recipe: recipe, ingredient: create(:ingredient, name: "baking powder"))
      create(:recipe_ingredient, recipe: recipe, ingredient: create(:ingredient, name: "cinnamon powder"))
      flour_step = create(:instruction, recipe: recipe, step_number: 1, description: "Whisk the flour and baking powder in a bowl.")

      described_class.call(recipe)

      expect(assigned_ingredient_ids(flour_step)).to contain_exactly(baking_powder.id)
    end

    it "assigns two ingredients with the same head noun when both are completely named in the same step" do
      recipe = create(:recipe)
      baking_powder = create(:recipe_ingredient, recipe: recipe, ingredient: create(:ingredient, name: "baking powder"))
      cinnamon_powder = create(:recipe_ingredient, recipe: recipe, ingredient: create(:ingredient, name: "cinnamon powder"))
      instruction = create(:instruction, recipe: recipe, description: "Combine the baking powder and cinnamon powder.")

      described_class.call(recipe)

      expect(assigned_ingredient_ids(instruction)).to contain_exactly(baking_powder.id, cinnamon_powder.id)
    end

    it "leaves two equally-qualifying ingredients with the same head noun unresolved" do
      recipe = create(:recipe)
      create(:recipe_ingredient, recipe: recipe, ingredient: create(:ingredient, name: "dark soy sauce"))
      create(:recipe_ingredient, recipe: recipe, ingredient: create(:ingredient, name: "light soy sauce"))
      instruction = create(:instruction, recipe: recipe, description: "Add the soy sauce.")

      described_class.call(recipe)

      expect(assigned_ingredient_ids(instruction)).to be_empty
    end
  end

  describe "group backfill from a matched instruction" do
    it "assigns an individually-matched ingredient's group from its instruction's structural tie" do
      recipe = create(:recipe)
      cake_group = create(:recipe_ingredient_group, recipe: recipe, name: "Cake")
      baking_powder = create(:recipe_ingredient, recipe: recipe, ingredient: create(:ingredient, name: "baking powder"), recipe_ingredient_group: nil)
      instruction = create(:instruction, recipe: recipe, recipe_ingredient_group: cake_group,
        description: "Whisk the flour, baking powder and salt in a bowl.")

      described_class.call(recipe)

      expect(assigned_ingredient_ids(instruction)).to contain_exactly(baking_powder.id)
      expect(baking_powder.reload.recipe_ingredient_group).to eq(cake_group)
    end

    it "leaves an ingredient ungrouped when its matched instruction has no structural group tie" do
      recipe = create(:recipe)
      salt = create(:recipe_ingredient, recipe: recipe, ingredient: create(:ingredient, name: "salt"), recipe_ingredient_group: nil)
      create(:instruction, recipe: recipe, recipe_ingredient_group: nil, description: "Season with salt to taste.")

      described_class.call(recipe)

      expect(salt.reload.recipe_ingredient_group).to be_nil
    end
  end

  describe "Tier 2.5: implied collective group" do
    it "groups an unnamed contiguous run and assigns it to the step that most directly names it" do
      recipe = create(:recipe)
      yoghurt = create(:recipe_ingredient, recipe: recipe, ingredient: create(:ingredient, name: "yoghurt"), position: 1)
      turmeric = create(:recipe_ingredient, recipe: recipe, ingredient: create(:ingredient, name: "turmeric"), position: 2)
      garlic = create(:recipe_ingredient, recipe: recipe, ingredient: create(:ingredient, name: "garlic"), position: 3)
      salt = create(:ingredient, name: "salt")
      create(:recipe_ingredient, recipe: recipe, ingredient: salt, position: 4)
      passing_mention = create(:instruction, recipe: recipe, step_number: 1,
        description: "Optional: blitz the Marinade ingredients in a food processor first.")
      primary_step = create(:instruction, recipe: recipe, step_number: 2,
        description: "Marinade: Combine the Marinade ingredients with the chicken and refrigerate.")
      salt_step = create(:instruction, recipe: recipe, step_number: 3, description: "Season with salt to taste.")

      described_class.call(recipe)

      expect(assigned_ingredient_ids(primary_step)).to contain_exactly(yoghurt.id, turmeric.id, garlic.id)
      expect(assigned_ingredient_ids(passing_mention)).to be_empty
      expect(assigned_ingredient_ids(salt_step)).to contain_exactly(RecipeIngredient.find_by(ingredient: salt).id)
      expect(recipe.recipe_ingredient_groups.pluck(:name)).to eq([ "Marinade" ])
    end

    it "does not treat a real ingredient name as a collective label" do
      recipe = create(:recipe)
      chicken = create(:ingredient, name: "chicken")
      create(:recipe_ingredient, recipe: recipe, ingredient: chicken, position: 1)
      onion = create(:ingredient, name: "onion")
      create(:recipe_ingredient, recipe: recipe, ingredient: onion, position: 2)
      instruction = create(:instruction, recipe: recipe,
        description: "Fry the Chicken until golden, then set aside.")

      described_class.call(recipe)

      expect(recipe.recipe_ingredient_groups).to be_empty
      expect(assigned_ingredient_ids(instruction)).to contain_exactly(RecipeIngredient.find_by(ingredient: chicken).id)
    end

    it "bails out when more than one contiguous unassigned run exists" do
      recipe = create(:recipe)
      create(:recipe_ingredient, recipe: recipe, ingredient: create(:ingredient, name: "yoghurt"), position: 1)
      create(:recipe_ingredient, recipe: recipe, ingredient: create(:ingredient, name: "turmeric"), position: 2)
      create(:recipe_ingredient, recipe: recipe, ingredient: create(:ingredient, name: "sugar"), position: 3)
      create(:recipe_ingredient, recipe: recipe, ingredient: create(:ingredient, name: "garlic"), position: 4)
      create(:recipe_ingredient, recipe: recipe, ingredient: create(:ingredient, name: "ginger"), position: 5)
      create(:instruction, recipe: recipe, step_number: 1,
        description: "Marinade: Combine the Marinade ingredients together.")
      create(:instruction, recipe: recipe, step_number: 2, description: "Stir in the sugar.")

      described_class.call(recipe)

      expect(recipe.recipe_ingredient_groups).to be_empty
      expect(InstructionIngredient.count).to eq(1) # only "sugar", via Tier 2 — the two runs either side of it stay unresolved
    end

    it "does not treat a single leftover ingredient as a collective section" do
      recipe = create(:recipe)
      create(:recipe_ingredient, recipe: recipe, ingredient: create(:ingredient, name: "cream"), position: 1)
      create(:instruction, recipe: recipe,
        description: "Stir in the Filling until smooth.")

      described_class.call(recipe)

      expect(recipe.recipe_ingredient_groups).to be_empty
      expect(InstructionIngredient.count).to eq(0)
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
