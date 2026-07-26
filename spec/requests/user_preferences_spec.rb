require 'rails_helper'

RSpec.describe "UserPreferences", type: :request do
  def log_in_as(user)
    post "/api/v1/login", params: { user: { email: user.email, password: "password123" } }
  end

  describe "GET /api/v1/user_preferences" do
    it "requires a logged-in user" do
      get "/api/v1/user_preferences"

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns the current user's planner preferences, defaulting everything visible" do
      user = create(:user)
      log_in_as(user)

      get "/api/v1/user_preferences"

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["show_breakfast"]).to be true
      expect(body["show_lunch"]).to be true
      expect(body["show_dinner"]).to be true
      expect(body["show_snack"]).to be true
      expect(body["home_view"]).to eq("random_recipes")
      expect(body["tandoor_import_enabled"]).to be false
    end
  end

  describe "PATCH /api/v1/user_preferences" do
    it "requires a logged-in user" do
      patch "/api/v1/user_preferences", params: { show_snack: false }

      expect(response).to have_http_status(:unauthorized)
    end

    it "updates meal-type visibility" do
      user = create(:user)
      log_in_as(user)

      patch "/api/v1/user_preferences", params: { show_snack: false, show_breakfast: false }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["show_snack"]).to be false
      expect(response.parsed_body["show_breakfast"]).to be false
      expect(response.parsed_body["show_lunch"]).to be true
      expect(user.reload.show_snack).to be false
    end

    it "updates home_view" do
      user = create(:user)
      log_in_as(user)

      patch "/api/v1/user_preferences", params: { home_view: "weekly_planner" }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["home_view"]).to eq("weekly_planner")
      expect(user.reload.home_view).to eq("weekly_planner")
    end

    it "updates tandoor_import_enabled" do
      user = create(:user)
      log_in_as(user)

      patch "/api/v1/user_preferences", params: { tandoor_import_enabled: true }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["tandoor_import_enabled"]).to be true
      expect(user.reload.tandoor_import_enabled).to be true
    end
  end
end
