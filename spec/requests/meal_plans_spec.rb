require 'rails_helper'

RSpec.describe "MealPlans", type: :request do
  def log_in_as(user)
    post "/api/v1/login", params: { user: { email: user.email, password: "password123" } }
  end

  describe "GET /api/v1/meal_plans" do
    it "requires a logged-in user" do
      get "/api/v1/meal_plans"

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns only the current user's meal plans within the given date range" do
      user = create(:user)
      log_in_as(user)
      in_range = create(:meal_plan, user: user, date: Date.new(2026, 7, 22))
      create(:meal_plan, user: user, date: Date.new(2026, 8, 1)) # out of range
      create(:meal_plan, user: create(:user), date: Date.new(2026, 7, 22)) # another user

      get "/api/v1/meal_plans", params: { start_date: "2026-07-20", end_date: "2026-07-26" }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.pluck("id")).to eq([ in_range.id ])
    end
  end

  describe "POST /api/v1/meal_plans" do
    it "requires a logged-in user" do
      post "/api/v1/meal_plans", params: { meal_plan: { date: Date.current, meal_type: "dinner" } }

      expect(response).to have_http_status(:unauthorized)
    end

    it "schedules one of the current user's own recipes" do
      user = create(:user)
      log_in_as(user)
      recipe = create(:recipe, user: user)

      post "/api/v1/meal_plans", params: { meal_plan: { recipe_id: recipe.id, date: "2026-07-22", meal_type: "dinner" } }

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["recipe"]["id"]).to eq(recipe.id)
      expect(response.parsed_body["label"]).to be_nil
    end

    it "404s when scheduling a recipe owned by someone else" do
      user = create(:user)
      log_in_as(user)
      other_recipe = create(:recipe, user: create(:user))

      post "/api/v1/meal_plans", params: { meal_plan: { recipe_id: other_recipe.id, date: "2026-07-22", meal_type: "dinner" } }

      expect(response).to have_http_status(:not_found)
    end

    it "schedules a freeform label with no recipe" do
      user = create(:user)
      log_in_as(user)

      post "/api/v1/meal_plans", params: { meal_plan: { label: "Eating out", date: "2026-07-22", meal_type: "lunch" } }

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["label"]).to eq("Eating out")
      expect(response.parsed_body["recipe"]).to be_nil
    end

    it "rejects a meal plan with neither a recipe nor a label" do
      user = create(:user)
      log_in_as(user)

      post "/api/v1/meal_plans", params: { meal_plan: { date: "2026-07-22", meal_type: "lunch" } }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "appends to the end of an existing slot's position" do
      user = create(:user)
      log_in_as(user)
      recipe = create(:recipe, user: user)
      create(:meal_plan, user: user, recipe: recipe, date: Date.new(2026, 7, 22), meal_type: "dinner", position: 3)

      post "/api/v1/meal_plans", params: { meal_plan: { recipe_id: recipe.id, date: "2026-07-22", meal_type: "dinner" } }

      expect(response.parsed_body["position"]).to eq(4)
    end
  end

  describe "PATCH /api/v1/meal_plans/:id" do
    it "requires a logged-in user" do
      meal_plan = create(:meal_plan, recipe: nil, label: "Leftovers")

      patch "/api/v1/meal_plans/#{meal_plan.id}", params: { meal_plan: { recipe_id: create(:recipe).id } }

      expect(response).to have_http_status(:unauthorized)
    end

    it "relinks a freeform entry to a recipe and clears its label" do
      user = create(:user)
      log_in_as(user)
      recipe = create(:recipe, user: user)
      meal_plan = create(:meal_plan, user: user, recipe: nil, label: "Leftovers")

      patch "/api/v1/meal_plans/#{meal_plan.id}", params: { meal_plan: { recipe_id: recipe.id } }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["recipe"]["id"]).to eq(recipe.id)
      expect(response.parsed_body["label"]).to be_nil
      expect(meal_plan.reload.label).to be_nil
    end

    it "404s when relinking to a recipe owned by someone else" do
      user = create(:user)
      log_in_as(user)
      other_recipe = create(:recipe, user: create(:user))
      meal_plan = create(:meal_plan, user: user, recipe: nil, label: "Leftovers")

      patch "/api/v1/meal_plans/#{meal_plan.id}", params: { meal_plan: { recipe_id: other_recipe.id } }

      expect(response).to have_http_status(:not_found)
    end

    it "404s for another user's meal plan" do
      user = create(:user)
      log_in_as(user)
      recipe = create(:recipe, user: user)
      other_plan = create(:meal_plan, user: create(:user), recipe: nil, label: "Leftovers")

      patch "/api/v1/meal_plans/#{other_plan.id}", params: { meal_plan: { recipe_id: recipe.id } }

      expect(response).to have_http_status(:not_found)
    end

    it "moves a plan to a different date and meal_type, appending to the end of the destination slot" do
      user = create(:user)
      log_in_as(user)
      recipe = create(:recipe, user: user)
      create(:meal_plan, user: user, recipe: recipe, date: Date.new(2026, 7, 23), meal_type: "lunch", position: 2)
      meal_plan = create(:meal_plan, user: user, recipe: recipe, date: Date.new(2026, 7, 22), meal_type: "dinner", position: 0)

      patch "/api/v1/meal_plans/#{meal_plan.id}", params: { meal_plan: { date: "2026-07-23", meal_type: "lunch" } }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["date"]).to eq("2026-07-23")
      expect(response.parsed_body["meal_type"]).to eq("lunch")
      expect(response.parsed_body["position"]).to eq(3)
    end

    it "dropping into its own slot again doesn't count itself when computing the new position" do
      user = create(:user)
      log_in_as(user)
      recipe = create(:recipe, user: user)
      meal_plan = create(:meal_plan, user: user, recipe: recipe, date: Date.new(2026, 7, 22), meal_type: "dinner", position: 5)

      patch "/api/v1/meal_plans/#{meal_plan.id}", params: { meal_plan: { date: "2026-07-22", meal_type: "dinner" } }

      expect(response.parsed_body["position"]).to eq(1)
    end
  end

  describe "DELETE /api/v1/meal_plans/:id" do
    it "requires a logged-in user" do
      meal_plan = create(:meal_plan)

      delete "/api/v1/meal_plans/#{meal_plan.id}"

      expect(response).to have_http_status(:unauthorized)
    end

    it "deletes the current user's meal plan" do
      user = create(:user)
      log_in_as(user)
      meal_plan = create(:meal_plan, user: user)

      delete "/api/v1/meal_plans/#{meal_plan.id}"

      expect(response).to have_http_status(:no_content)
      expect(MealPlan.exists?(meal_plan.id)).to be false
    end

    it "404s for another user's meal plan" do
      user = create(:user)
      log_in_as(user)
      other_plan = create(:meal_plan, user: create(:user))

      delete "/api/v1/meal_plans/#{other_plan.id}"

      expect(response).to have_http_status(:not_found)
    end
  end
end
