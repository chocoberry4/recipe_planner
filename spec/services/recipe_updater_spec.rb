require 'rails_helper'

RSpec.describe RecipeUpdater do
  def call(recipe, params)
    described_class.call(recipe, params)
  end

  it "updates title and description" do
    recipe = create(:recipe)

    result = call(recipe, { title: "New Title", description: "New description" })

    expect(result).to be_ok
    expect(result.recipe.title).to eq("New Title")
    expect(result.recipe.description).to eq("New description")
  end

  it "updates duration_minutes" do
    recipe = create(:recipe)

    result = call(recipe, { duration_minutes: 45 })

    expect(result).to be_ok
    expect(result.recipe.duration_minutes).to eq(45)
  end

  it "rolls back and returns errors when a base field is invalid" do
    recipe = create(:recipe, title: "Original")

    result = call(recipe, { title: "Original", description: "" })

    expect(result).not_to be_ok
    expect(result.errors).to include("Description can't be blank")
    expect(recipe.reload.title).to eq("Original")
  end

  describe "ungrouped ingredients" do
    it "adds a new ingredient with no id" do
      recipe = create(:recipe)

      result = call(recipe, {
        ingredients: [
          { name: "flour", quantity: 2, unit: "cups", preparation: "sifted", position: 1 }
        ]
      })

      expect(result).to be_ok
      ri = result.recipe.recipe_ingredients.sole
      expect(ri.ingredient.name).to eq("flour")
      expect(ri.quantity).to eq(2)
      expect(ri.unit).to eq("cups")
      expect(ri.preparation).to eq("sifted")
    end

    it "silently skips a new ingredient row left blank" do
      recipe = create(:recipe)

      result = call(recipe, { ingredients: [ { name: "", quantity: nil } ] })

      expect(result).to be_ok
      expect(result.recipe.recipe_ingredients).to be_empty
    end

    it "edits an existing ingredient's quantity/unit/preparation and renames it without mutating the shared Ingredient row" do
      shared_ingredient = create(:ingredient, name: "garlic clove")
      other_recipe = create(:recipe)
      create(:recipe_ingredient, recipe: other_recipe, ingredient: shared_ingredient)

      recipe = create(:recipe)
      ri = create(:recipe_ingredient, recipe: recipe, ingredient: shared_ingredient, quantity: 2, unit: nil, preparation: nil)

      result = call(recipe, {
        ingredients: [
          { id: ri.id, name: "garlic", quantity: 1, unit: "clove", preparation: "minced", position: 1 }
        ]
      })

      expect(result).to be_ok
      ri.reload
      expect(ri.ingredient.name).to eq("garlic")
      expect(ri.quantity).to eq(1)
      expect(ri.unit).to eq("clove")
      expect(ri.preparation).to eq("minced")

      # The original shared Ingredient row is untouched - other recipes
      # pointing at it by name aren't retroactively renamed.
      expect(shared_ingredient.reload.name).to eq("garlic clove")
    end

    it "removes an ingredient and cleans up its instruction_ingredient assignments" do
      recipe = create(:recipe)
      ri = create(:recipe_ingredient, recipe: recipe)
      step = create(:instruction, recipe: recipe)
      create(:instruction_ingredient, instruction: step, recipe_ingredient: ri)

      result = call(recipe, { ingredients: [ { id: ri.id, _destroy: true } ] })

      expect(result).to be_ok
      expect(RecipeIngredient.exists?(ri.id)).to be false
      expect(InstructionIngredient.where(recipe_ingredient_id: ri.id)).to be_empty
    end

    it "rolls back when renaming an existing ingredient to blank" do
      recipe = create(:recipe)
      ri = create(:recipe_ingredient, recipe: recipe, ingredient: create(:ingredient, name: "salt"))

      result = call(recipe, { ingredients: [ { id: ri.id, name: "", quantity: 1 } ] })

      expect(result).not_to be_ok
      expect(ri.reload.ingredient.name).to eq("salt")
    end
  end

  describe "ingredient groups" do
    it "creates a new group with a nested new ingredient" do
      recipe = create(:recipe)

      result = call(recipe, {
        recipe_ingredient_groups: [
          {
            name: "Marinade",
            position: 1,
            recipe_ingredients: [
              { name: "soy sauce", quantity: 2, unit: "tbsp", position: 1 }
            ]
          }
        ]
      })

      expect(result).to be_ok
      group = result.recipe.recipe_ingredient_groups.sole
      expect(group.name).to eq("Marinade")
      ri = group.recipe_ingredients.sole
      expect(ri.ingredient.name).to eq("soy sauce")
    end

    it "renames an existing group" do
      recipe = create(:recipe)
      group = create(:recipe_ingredient_group, recipe: recipe, name: "Filling")

      result = call(recipe, { recipe_ingredient_groups: [ { id: group.id, name: "Topping", position: 2 } ] })

      expect(result).to be_ok
      expect(group.reload.name).to eq("Topping")
      expect(group.position).to eq(2)
    end

    it "destroys a group and falls back its still-nested ingredients to ungrouped rather than losing them" do
      recipe = create(:recipe)
      group = create(:recipe_ingredient_group, recipe: recipe, name: "Marinade")
      ri = create(:recipe_ingredient, recipe: recipe, recipe_ingredient_group: group)

      result = call(recipe, {
        recipe_ingredient_groups: [
          { id: group.id, _destroy: true, recipe_ingredients: [ { id: ri.id, name: ri.ingredient.name, quantity: ri.quantity, unit: ri.unit } ] }
        ]
      })

      expect(result).to be_ok
      expect(RecipeIngredientGroup.exists?(group.id)).to be false
      expect(ri.reload.recipe_ingredient_group_id).to be_nil
    end

    it "does not create a group left with a blank name, but preserves any nested ingredients as ungrouped" do
      recipe = create(:recipe)

      result = call(recipe, {
        recipe_ingredient_groups: [
          { name: "", position: 1, recipe_ingredients: [ { name: "salt", quantity: nil } ] }
        ]
      })

      expect(result).to be_ok
      expect(result.recipe.recipe_ingredient_groups).to be_empty
      ri = result.recipe.recipe_ingredients.sole
      expect(ri.ingredient.name).to eq("salt")
      expect(ri.recipe_ingredient_group_id).to be_nil
    end
  end

  describe "tags" do
    it "assigns tags by name, creating new Tag rows as needed" do
      recipe = create(:recipe)

      result = call(recipe, { tag_names: [ "Dessert", "quick" ] })

      expect(result).to be_ok
      expect(result.recipe.tags.pluck(:name)).to contain_exactly("dessert", "quick")
    end

    it "reuses an existing tag regardless of the casing it's re-typed with" do
      create(:tag, name: "dessert")
      recipe = create(:recipe)

      result = call(recipe, { tag_names: [ "Dessert" ] })

      expect(result).to be_ok
      expect(Tag.where(name: "dessert").count).to eq(1)
    end

    it "removes tags no longer present in the list" do
      recipe = create(:recipe)
      recipe.tags << create(:tag, name: "old")

      result = call(recipe, { tag_names: [] })

      expect(result).to be_ok
      expect(result.recipe.tags).to be_empty
    end

    it "leaves existing tags untouched when tag_names is omitted entirely" do
      recipe = create(:recipe)
      recipe.tags << create(:tag, name: "keep-me")

      result = call(recipe, { title: recipe.title, description: recipe.description })

      expect(result).to be_ok
      expect(result.recipe.tags.pluck(:name)).to eq([ "keep-me" ])
    end

    it "strips whitespace and drops blank/duplicate entries" do
      recipe = create(:recipe)

      result = call(recipe, { tag_names: [ " spicy ", "spicy", "Spicy", "" ] })

      expect(result).to be_ok
      expect(result.recipe.tags.pluck(:name)).to eq([ "spicy" ])
    end
  end

  describe "instructions" do
    it "adds a new instruction with no id" do
      recipe = create(:recipe)

      result = call(recipe, { instructions: [ { description: "Preheat the oven.", step_number: 1 } ] })

      expect(result).to be_ok
      expect(result.recipe.instructions.sole.description).to eq("Preheat the oven.")
    end

    it "silently skips a new instruction row left blank" do
      recipe = create(:recipe)

      result = call(recipe, { instructions: [ { description: "" } ] })

      expect(result).to be_ok
      expect(result.recipe.instructions).to be_empty
    end

    it "edits an existing instruction's description and step_number" do
      recipe = create(:recipe)
      step = create(:instruction, recipe: recipe, description: "Old text", step_number: 1)

      result = call(recipe, { instructions: [ { id: step.id, description: "New text", step_number: 2 } ] })

      expect(result).to be_ok
      expect(step.reload.description).to eq("New text")
      expect(step.step_number).to eq(2)
    end

    it "removes an instruction" do
      recipe = create(:recipe)
      step = create(:instruction, recipe: recipe)

      result = call(recipe, { instructions: [ { id: step.id, _destroy: true } ] })

      expect(result).to be_ok
      expect(Instruction.exists?(step.id)).to be false
    end

    it "sets an instruction's image_url" do
      recipe = create(:recipe)
      step = create(:instruction, recipe: recipe, description: "Whisk the eggs.")

      result = call(recipe, {
        instructions: [ { id: step.id, description: step.description, image_url: "https://example.com/step.jpg" } ]
      })

      expect(result).to be_ok
      expect(step.reload.image_url).to eq("https://example.com/step.jpg")
    end
  end
end
