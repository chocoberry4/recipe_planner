require 'rails_helper'

RSpec.describe "Auth", type: :request do
  describe "POST /api/v1/signup" do
    it "creates a user and starts a session" do
      post "/api/v1/signup", params: { user: { email: "new@example.com", username: "newuser", password: "password123" } }

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["email"]).to eq("new@example.com")
      expect(session[:user_id]).to eq(User.last.id)
    end

    it "rejects an invalid signup" do
      post "/api/v1/signup", params: { user: { email: "", password: "short" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(session[:user_id]).to be_nil
    end
  end

  describe "POST /api/v1/login" do
    let!(:user) { create(:user, password: "password123") }

    it "logs in with valid credentials" do
      post "/api/v1/login", params: { user: { email: user.email, password: "password123" } }

      expect(response).to have_http_status(:ok)
      expect(session[:user_id]).to eq(user.id)
    end

    it "rejects invalid credentials" do
      post "/api/v1/login", params: { user: { email: user.email, password: "wrongpassword" } }

      expect(response).to have_http_status(:unauthorized)
      expect(session[:user_id]).to be_nil
    end

    it "rejects an unknown email" do
      post "/api/v1/login", params: { user: { email: "nobody@example.com", password: "password123" } }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /api/v1/logout" do
    let!(:user) { create(:user, password: "password123") }

    it "clears the session" do
      post "/api/v1/login", params: { user: { email: user.email, password: "password123" } }
      expect(session[:user_id]).to eq(user.id)

      # Logout isn't exempt from forgery protection (unlike signup/login, a
      # session already exists at this point), so it needs the CSRF token
      # the server handed back, just like a real browser would send it.
      delete "/api/v1/logout", headers: { "X-CSRF-Token" => cookies["CSRF-TOKEN"] }

      expect(response).to have_http_status(:no_content)
      expect(session[:user_id]).to be_nil
    end
  end

  describe "GET /api/v1/me" do
    let!(:user) { create(:user, password: "password123") }

    it "returns 401 when logged out" do
      get "/api/v1/me"

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns the current user when logged in" do
      post "/api/v1/login", params: { user: { email: user.email, password: "password123" } }

      get "/api/v1/me"

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["email"]).to eq(user.email)
    end
  end

  describe "unauthenticated access to recipe mutations" do
    # Recipe browsing (index/show) is intentionally left public; that's
    # already covered by the existing GET /api/v1/recipes spec. Enforcing
    # auth there would touch spec/requests/recipe_spec.rb, which the
    # ingredient-grouping-schema track is actively extending in parallel, so
    # only the mutation path (which recipes genuinely need a user for) is
    # asserted here.
    it "rejects recipe creation without a session" do
      # Any visitor picks up a CSRF token cookie on their first request (see
      # Api::BaseController#set_csrf_cookie); send it along so this request
      # is rejected for lacking a session, not for lacking that token.
      get "/api/v1/recipes"

      post "/api/v1/recipes",
        params: { recipe: { title: "Test", description: "Test" } },
        headers: { "X-CSRF-Token" => cookies["CSRF-TOKEN"] }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
