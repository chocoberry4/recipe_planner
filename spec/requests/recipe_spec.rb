require 'rails_helper'

RSpec.describe "Recipes", type: :request do
  # Recipes are private to their owner (see RecipesController) - every
  # action needs a logged-in user, scoped to that user's own recipes.
  def log_in_as(user)
    post "/api/v1/login", params: { user: { email: user.email, password: "password123" } }
  end

  describe "GET /api/v1/recipes" do
    it "requires a logged-in user" do
      get "/api/v1/recipes"

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns only the logged-in user's own recipes" do
      user = create(:user)
      own_recipes = create_list(:recipe, 2, user: user)
      create_list(:recipe, 3) # someone else's

      log_in_as(user)
      get "/api/v1/recipes"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body.map { |r| r["id"] }).to contain_exactly(*own_recipes.map(&:id))
    end
  end

  describe "GET /api/v1/recipes/:id" do
    it "requires a logged-in user" do
      recipe = create(:recipe)

      get "/api/v1/recipes/#{recipe.id}"

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns the requested recipe" do
      recipe = create(:recipe)
      log_in_as(recipe.user)

      get "/api/v1/recipes/#{recipe.id}"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["id"]).to eq(recipe.id)
      expect(body["title"]).to eq(recipe.title)
      expect(body["description"]).to eq(recipe.description)
    end

    it "serializes grouped and ungrouped ingredients with their preparation" do
      recipe = create(:recipe)
      log_in_as(recipe.user)
      group = create(:recipe_ingredient_group, recipe: recipe, name: "Marinade")
      grouped_ingredient = create(:recipe_ingredient, recipe: recipe, recipe_ingredient_group: group, preparation: "minced")
      ungrouped_ingredient = create(:recipe_ingredient, recipe: recipe)

      get "/api/v1/recipes/#{recipe.id}"

      body = JSON.parse(response.body)
      expect(body["recipe_ingredient_groups"].length).to eq(1)
      expect(body["recipe_ingredient_groups"].first["name"]).to eq("Marinade")
      expect(body["recipe_ingredient_groups"].first["recipe_ingredients"].first["id"]).to eq(grouped_ingredient.id)
      expect(body["recipe_ingredient_groups"].first["recipe_ingredients"].first["preparation"]).to eq("minced")
      expect(body["ingredients"].map { |i| i["id"] }).to contain_exactly(ungrouped_ingredient.id)
    end

    it "serializes each instruction's assigned recipe_ingredient_ids" do
      recipe = create(:recipe)
      log_in_as(recipe.user)
      salt_ri = create(:recipe_ingredient, recipe: recipe, ingredient: create(:ingredient, name: "salt"))
      unresolved_ri = create(:recipe_ingredient, recipe: recipe, ingredient: create(:ingredient, name: "pepper"))
      step = create(:instruction, recipe: recipe)
      create(:instruction_ingredient, instruction: step, recipe_ingredient: salt_ri)

      get "/api/v1/recipes/#{recipe.id}"

      body = JSON.parse(response.body)
      step_json = body["instructions"].find { |i| i["id"] == step.id }
      expect(step_json["recipe_ingredient_ids"]).to eq([ salt_ri.id ])
      expect(body["ingredients"].map { |i| i["id"] }).to include(unresolved_ri.id)
    end

    it "serializes each instruction's image_url" do
      recipe = create(:recipe)
      log_in_as(recipe.user)
      step = create(:instruction, recipe: recipe, image_url: "https://example.com/step.jpg")

      get "/api/v1/recipes/#{recipe.id}"

      body = JSON.parse(response.body)
      step_json = body["instructions"].find { |i| i["id"] == step.id }
      expect(step_json["image_url"]).to eq("https://example.com/step.jpg")
    end

    it "returns not_found for a missing recipe" do
      log_in_as(create(:user))

      get "/api/v1/recipes/999999"

      expect(response).to have_http_status(:not_found)
    end

    it "returns not_found (not the recipe) for another user's recipe" do
      recipe = create(:recipe)
      log_in_as(create(:user))

      get "/api/v1/recipes/#{recipe.id}"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/recipes" do
    it "returns unprocessable_entity when required fields are missing" do
      log_in_as(create(:user))

      post "/api/v1/recipes", params: { recipe: { title: "", description: "" } }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "creates a new recipe owned by the logged-in user" do
      user = create(:user)
      log_in_as(user)

      post "/api/v1/recipes", params: { recipe: { title: "Tacos", description: "Weeknight tacos" } }

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["title"]).to eq("Tacos")
      expect(Recipe.find(body["id"]).user).to eq(user)
    end
  end

  describe "PATCH /api/v1/recipes/:id" do
    it "returns unprocessable_entity when the update is invalid" do
      recipe = create(:recipe)
      log_in_as(recipe.user)

      patch "/api/v1/recipes/#{recipe.id}", params: { recipe: { description: "" } }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "updates the recipe" do
      recipe = create(:recipe)
      log_in_as(recipe.user)

      patch "/api/v1/recipes/#{recipe.id}", params: { recipe: { title: "New Title" } }

      expect(response).to have_http_status(:ok)
      expect(recipe.reload.title).to eq("New Title")
    end

    it "returns not_found when a non-owner tries to update the recipe" do
      recipe = create(:recipe)
      log_in_as(create(:user))

      patch "/api/v1/recipes/#{recipe.id}", params: { recipe: { title: "Hijacked" } }

      expect(response).to have_http_status(:not_found)
      expect(recipe.reload.title).not_to eq("Hijacked")
    end

    it "accepts nested ingredient/instruction edits, additions, and removals" do
      recipe = create(:recipe)
      log_in_as(recipe.user)
      group = create(:recipe_ingredient_group, recipe: recipe, name: "Marinade")
      keep = create(:recipe_ingredient, recipe: recipe, recipe_ingredient_group: group, ingredient: create(:ingredient, name: "soy sauce"))
      remove = create(:recipe_ingredient, recipe: recipe)
      step = create(:instruction, recipe: recipe, description: "Old step")

      patch "/api/v1/recipes/#{recipe.id}", params: {
        recipe: {
          recipe_ingredient_groups: [
            { id: group.id, name: "Marinade",
              recipe_ingredients: [ { id: keep.id, name: "soy sauce", quantity: 3, unit: "tbsp" } ] }
          ],
          ingredients: [
            { id: remove.id, _destroy: true },
            { name: "garlic", quantity: 1, unit: "clove", preparation: "minced" }
          ],
          instructions: [
            { id: step.id, description: "New step", step_number: 1 }
          ]
        }
      }, as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(keep.reload.quantity).to eq(3)
      expect(RecipeIngredient.exists?(remove.id)).to be false
      expect(step.reload.description).to eq("New step")
      expect(body["ingredients"].map { |i| i["name"] }).to include("garlic")
    end

    it "updates an instruction's image_url" do
      recipe = create(:recipe)
      log_in_as(recipe.user)
      step = create(:instruction, recipe: recipe, description: "Whisk the eggs.")

      patch "/api/v1/recipes/#{recipe.id}", params: {
        recipe: { instructions: [ { id: step.id, description: step.description, image_url: "https://example.com/step.jpg" } ] }
      }, as: :json

      expect(response).to have_http_status(:ok)
      expect(step.reload.image_url).to eq("https://example.com/step.jpg")
    end
  end

  describe "DELETE /api/v1/recipes/:id" do
    it "deletes the recipe" do
      recipe = create(:recipe)
      log_in_as(recipe.user)

      delete "/api/v1/recipes/#{recipe.id}"

      expect(response).to have_http_status(:no_content)
      expect(Recipe.exists?(recipe.id)).to be false
    end

    it "returns not_found when a non-owner tries to delete the recipe" do
      recipe = create(:recipe)
      log_in_as(create(:user))

      delete "/api/v1/recipes/#{recipe.id}"

      expect(response).to have_http_status(:not_found)
      expect(Recipe.exists?(recipe.id)).to be true
    end
  end
end
