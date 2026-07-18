require 'rails_helper'

RSpec.describe "InstructionIngredients", type: :request do
  def log_in_as(user)
    post "/api/v1/login", params: { user: { email: user.email, password: "password123" } }
  end

  describe "PATCH /api/v1/recipes/:recipe_id/instruction_ingredients" do
    it "requires a logged-in user" do
      recipe = create(:recipe)

      patch "/api/v1/recipes/#{recipe.id}/instruction_ingredients", params: { assignments: {} }

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns not_found for a non-owner" do
      recipe = create(:recipe)
      log_in_as(create(:user))

      patch "/api/v1/recipes/#{recipe.id}/instruction_ingredients", params: { assignments: {} }

      expect(response).to have_http_status(:not_found)
    end

    it "replaces the instruction_ingredients set to match the submitted assignments" do
      recipe = create(:recipe)
      log_in_as(recipe.user)
      salt = create(:ingredient, name: "salt")
      pepper = create(:ingredient, name: "pepper")
      salt_ri = create(:recipe_ingredient, recipe: recipe, ingredient: salt)
      pepper_ri = create(:recipe_ingredient, recipe: recipe, ingredient: pepper)
      step1 = create(:instruction, recipe: recipe, step_number: 1)
      step2 = create(:instruction, recipe: recipe, step_number: 2)
      # Wrong initial assignment, as if the autosorter guessed badly.
      create(:instruction_ingredient, instruction: step1, recipe_ingredient: pepper_ri)

      patch "/api/v1/recipes/#{recipe.id}/instruction_ingredients", params: {
        assignments: { step1.id => [ salt_ri.id ], step2.id => [ pepper_ri.id ] }
      }

      expect(response).to have_http_status(:ok)
      expect(step1.reload.recipe_ingredients).to contain_exactly(salt_ri)
      expect(step2.reload.recipe_ingredients).to contain_exactly(pepper_ri)
    end

    it "leaves an instruction with no assignments when its key is omitted" do
      recipe = create(:recipe)
      log_in_as(recipe.user)
      salt_ri = create(:recipe_ingredient, recipe: recipe, ingredient: create(:ingredient, name: "salt"))
      step1 = create(:instruction, recipe: recipe, step_number: 1)
      create(:instruction_ingredient, instruction: step1, recipe_ingredient: salt_ri)

      patch "/api/v1/recipes/#{recipe.id}/instruction_ingredients", params: { assignments: {} }

      expect(step1.reload.recipe_ingredients).to be_empty
    end

    it "ignores instruction_ids and recipe_ingredient_ids that belong to a different recipe" do
      recipe = create(:recipe)
      log_in_as(recipe.user)
      step1 = create(:instruction, recipe: recipe, step_number: 1)

      other_recipe = create(:recipe)
      other_ri = create(:recipe_ingredient, recipe: other_recipe, ingredient: create(:ingredient, name: "cumin"))
      other_step = create(:instruction, recipe: other_recipe, step_number: 1)

      patch "/api/v1/recipes/#{recipe.id}/instruction_ingredients", params: {
        assignments: { step1.id => [ other_ri.id ], other_step.id => [ other_ri.id ] }
      }

      expect(response).to have_http_status(:ok)
      expect(InstructionIngredient.count).to eq(0)
    end
  end
end
