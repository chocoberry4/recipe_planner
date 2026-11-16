require "rails_helper"

RSpec.describe "ShoppingItems", type: :request do
  def log_in_as(user)
    post "/api/v1/login", params: { user: { email: user.email, password: "password123" } }
  end

  let(:user) { create(:user) }

  it "requires login" do
    get "/api/v1/shopping_items"
    expect(response).to have_http_status(:unauthorized)
  end

  describe "GET /api/v1/shopping_items" do
    it "lists only the current user's items, unchecked first" do
      log_in_as(user)
      done = create(:shopping_item, user: user, name: "milk", checked: true)
      todo = create(:shopping_item, user: user, name: "eggs")
      create(:shopping_item, name: "someone else's")

      get "/api/v1/shopping_items"

      expect(JSON.parse(response.body).map { |i| i["id"] }).to eq([ todo.id, done.id ])
    end
  end

  describe "POST /api/v1/shopping_items" do
    before { log_in_as(user) }

    it "creates an item" do
      post "/api/v1/shopping_items", params: { shopping_item: { name: "  kitchen   roll ", quantity: 2, unit: "" } }

      expect(response).to have_http_status(:created)
      item = user.shopping_items.last
      expect([ item.name, item.quantity.to_f, item.unit ]).to eq([ "kitchen roll", 2.0, nil ])
    end

    it "rejects a blank name" do
      post "/api/v1/shopping_items", params: { shopping_item: { name: " " } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(user.shopping_items.count).to eq(0)
    end

    it "sums quantities into an existing item with the same name and unit" do
      create(:shopping_item, user: user, name: "Flour", quantity: 100, unit: "g")

      post "/api/v1/shopping_items", params: { shopping_item: { name: "flour", quantity: 50, unit: "g" } }

      expect(response).to have_http_status(:ok)
      expect(user.shopping_items.count).to eq(1)
      expect(user.shopping_items.first.quantity.to_f).to eq(150.0)
    end

    it "keeps a different unit as its own line" do
      create(:shopping_item, user: user, name: "flour", quantity: 100, unit: "g")

      post "/api/v1/shopping_items", params: { shopping_item: { name: "flour", quantity: 1, unit: "bag" } }

      expect(user.shopping_items.count).to eq(2)
    end

    it "unchecks an existing item when it is added again" do
      item = create(:shopping_item, user: user, name: "salt", checked: true)

      post "/api/v1/shopping_items", params: { shopping_item: { name: "salt" } }

      expect(item.reload.checked).to be(false)
      expect(user.shopping_items.count).to eq(1)
    end
  end

  describe "PATCH /api/v1/shopping_items/:id" do
    before { log_in_as(user) }

    it "toggles checked" do
      item = create(:shopping_item, user: user)

      patch "/api/v1/shopping_items/#{item.id}", params: { shopping_item: { checked: true } }

      expect(item.reload.checked).to be(true)
    end

    it "404s for someone else's item" do
      other = create(:shopping_item)

      patch "/api/v1/shopping_items/#{other.id}", params: { shopping_item: { checked: true } }

      expect(response).to have_http_status(:not_found)
      expect(other.reload.checked).to be(false)
    end
  end

  describe "DELETE" do
    before { log_in_as(user) }

    it "removes an item, but not someone else's" do
      mine = create(:shopping_item, user: user)
      other = create(:shopping_item)

      delete "/api/v1/shopping_items/#{mine.id}"
      expect(response).to have_http_status(:no_content)
      delete "/api/v1/shopping_items/#{other.id}"

      expect(response).to have_http_status(:not_found)
      expect(ShoppingItem.exists?(other.id)).to be(true)
    end

    it "clears only the current user's checked items" do
      create(:shopping_item, user: user, name: "a", checked: true)
      keep = create(:shopping_item, user: user, name: "b")
      other = create(:shopping_item, checked: true)

      delete "/api/v1/shopping_items/checked"

      expect(user.shopping_items.pluck(:id)).to eq([ keep.id ])
      expect(ShoppingItem.exists?(other.id)).to be(true)
    end
  end
end
