require "rails_helper"

RSpec.describe "RecipeAutosorts", type: :request do
  def log_in_as(user)
    post "/api/v1/login", params: { user: { email: user.email, password: "password123" } }
  end

  describe "POST /api/v1/recipes/:recipe_id/autosort" do
    it "requires a logged-in user" do
      recipe = create(:recipe)

      post "/api/v1/recipes/#{recipe.id}/autosort"

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns not_found for a non-owner" do
      recipe = create(:recipe)
      log_in_as(create(:user))

      post "/api/v1/recipes/#{recipe.id}/autosort"

      expect(response).to have_http_status(:not_found)
    end

    it "re-matches ingredients to the steps whose text names them, replacing old assignments" do
      recipe = create(:recipe)
      log_in_as(recipe.user)
      chicken_ri = create(:recipe_ingredient, recipe: recipe, ingredient: create(:ingredient, name: "chicken"))
      rice_ri = create(:recipe_ingredient, recipe: recipe, ingredient: create(:ingredient, name: "rice"))
      step1 = create(:instruction, recipe: recipe, step_number: 1, description: "Fry the chicken until golden.")
      step2 = create(:instruction, recipe: recipe, step_number: 2, description: "Serve over the rice.")
      # Stale assignment from before the step was split: everything on step 1.
      create(:instruction_ingredient, instruction: step1, recipe_ingredient: chicken_ri)
      create(:instruction_ingredient, instruction: step1, recipe_ingredient: rice_ri)

      post "/api/v1/recipes/#{recipe.id}/autosort"

      expect(response).to have_http_status(:ok)
      expect(step1.reload.instruction_ingredients.map(&:recipe_ingredient_id)).to eq([ chicken_ri.id ])
      expect(step2.reload.instruction_ingredients.map(&:recipe_ingredient_id)).to eq([ rice_ri.id ])
      body = JSON.parse(response.body)
      expect(body["instructions"].map { |i| i["recipe_ingredient_ids"] }).to eq([ [ chicken_ri.id ], [ rice_ri.id ] ])
    end

    it "does not touch another user's recipe assignments" do
      other = create(:recipe)
      ri = create(:recipe_ingredient, recipe: other)
      step = create(:instruction, recipe: other)
      create(:instruction_ingredient, instruction: step, recipe_ingredient: ri)
      log_in_as(create(:user))

      post "/api/v1/recipes/#{other.id}/autosort"

      expect(step.reload.instruction_ingredients.count).to eq(1)
    end
  end
end
