require 'rails_helper'

RSpec.describe "RecipeImports", type: :request do
  def log_in_as(user)
    post "/api/v1/login", params: { user: { email: user.email, password: "password123" } }
  end

  describe "POST /api/v1/recipes/import" do
    it "requires a logged-in user" do
      post "/api/v1/recipes/import", params: { ingredients_text: "2 eggs", instructions_text: "Whisk." }

      expect(response).to have_http_status(:unauthorized)
    end

    it "imports from pasted text and returns the created recipe" do
      user = create(:user)
      log_in_as(user)

      post "/api/v1/recipes/import", params: {
        title: "Tacos",
        description: "Weeknight tacos",
        ingredients_text: "2 eggs\n1 cup flour",
        instructions_text: "Whisk the eggs.\nAdd the flour."
      }

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["title"]).to eq("Tacos")
      expect(body["user_id"]).to eq(user.id)
      expect(body["ingredients"].length).to eq(2)
      expect(body["instructions"].length).to eq(2)
    end

    it "imports from a URL by delegating to RecipeImporter.from_url" do
      user = create(:user)
      log_in_as(user)
      recipe = create(:recipe, user: user, title: "Imported Tacos")
      allow(RecipeImporter).to receive(:from_url)
        .with("https://example.com/tacos", user: kind_of(User))
        .and_return(RecipeImporter::Result.new(ok: true, recipe: recipe, reason: nil))

      post "/api/v1/recipes/import", params: { url: "https://example.com/tacos" }

      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)["title"]).to eq("Imported Tacos")
    end

    it "returns unprocessable_entity with the failure reason when import fails" do
      user = create(:user)
      log_in_as(user)
      allow(RecipeImporter).to receive(:from_url)
        .and_return(RecipeImporter::Result.new(ok: false, recipe: nil, reason: :no_structured_data))

      post "/api/v1/recipes/import", params: { url: "https://example.com/no-recipe" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["error"]).to eq("no_structured_data")
    end
  end
end
