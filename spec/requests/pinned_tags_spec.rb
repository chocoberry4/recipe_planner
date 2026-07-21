require 'rails_helper'

RSpec.describe "PinnedTags", type: :request do
  def log_in_as(user)
    post "/api/v1/login", params: { user: { email: user.email, password: "password123" } }
  end

  describe "GET /api/v1/pinned_tags" do
    it "requires a logged-in user" do
      get "/api/v1/pinned_tags"

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns the current user's pinned tags, alphabetically" do
      user = create(:user)
      log_in_as(user)
      zebra = create(:tag, name: "zebra")
      apple = create(:tag, name: "apple")
      user.pinned_tags = [ zebra, apple ]

      get "/api/v1/pinned_tags"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.pluck("name")).to eq([ "apple", "zebra" ])
    end

    it "does not include another user's pinned tags" do
      user = create(:user)
      log_in_as(user)
      other_user = create(:user)
      other_user.pinned_tags = [ create(:tag, name: "not-mine") ]

      get "/api/v1/pinned_tags"

      expect(response.parsed_body).to eq([])
    end
  end

  describe "PATCH /api/v1/pinned_tags" do
    it "requires a logged-in user" do
      patch "/api/v1/pinned_tags", params: { tag_ids: [] }

      expect(response).to have_http_status(:unauthorized)
    end

    it "replaces the pinned set to match the submitted tag_ids" do
      user = create(:user)
      log_in_as(user)
      keep = create(:tag, name: "keep")
      drop = create(:tag, name: "drop")
      add = create(:tag, name: "add")
      user.pinned_tags = [ keep, drop ]

      patch "/api/v1/pinned_tags", params: { tag_ids: [ keep.id, add.id ] }

      expect(response).to have_http_status(:ok)
      expect(user.reload.pinned_tags).to contain_exactly(keep, add)
    end

    it "unpins everything when tag_ids is omitted" do
      user = create(:user)
      log_in_as(user)
      user.pinned_tags = [ create(:tag, name: "solo") ]

      patch "/api/v1/pinned_tags", params: {}

      expect(response).to have_http_status(:ok)
      expect(user.reload.pinned_tags).to be_empty
    end
  end
end
