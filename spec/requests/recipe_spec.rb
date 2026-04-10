require 'rails_helper'

RSpec.describe "Recipes", type: :request do
  describe "GET /api/v1/recipes" do
    it "returns a list of recipes" do
      create_list(:recipe, 3)

      get "/api/v1/recipes"
      
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).length).to eq(3)
    end
  end
end
