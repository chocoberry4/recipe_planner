require "rails_helper"

RSpec.describe "TandoorImports", type: :request do
  def log_in_as(user)
    post "/api/v1/login", params: { user: { email: user.email, password: "password123" } }
  end

  # A minimal single-recipe Tandoor export: recipe.json at the top level of
  # the zip, no nested per-recipe zip and no image - the simplest shape
  # TandoorImporter accepts.
  def build_tandoor_zip(recipe_data)
    Tempfile.new([ "tandoor-export", ".zip" ]).tap do |tempfile|
      tempfile.binmode
      buffer = Zip::OutputStream.write_buffer do |zip|
        zip.put_next_entry("recipe.json")
        zip.write(recipe_data.to_json)
      end
      tempfile.write(buffer.string)
      tempfile.rewind
    end
  end

  def valid_recipe_data(name: "Test Recipe")
    {
      name: name,
      description: "A recipe for testing",
      steps: [
        { instruction: "Mix everything.", ingredients: [ { food: { name: "Flour" }, amount: 2, unit: { name: "cups" } } ] }
      ]
    }
  end

  describe "POST /api/v1/tandoor_imports" do
    it "requires a logged-in user" do
      post "/api/v1/tandoor_imports"

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns an error when no file is uploaded" do
      log_in_as(create(:user))

      post "/api/v1/tandoor_imports"

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["errors"]).to include("No file was uploaded")
    end

    it "creates a pending import, attaches the zip, and enqueues the processing job" do
      user = create(:user)
      log_in_as(user)
      zip = build_tandoor_zip(valid_recipe_data)

      expect {
        post "/api/v1/tandoor_imports", params: { file: Rack::Test::UploadedFile.new(zip.path, "application/zip") }
      }.to have_enqueued_job(TandoorImportJob)

      expect(response).to have_http_status(:accepted)
      body = JSON.parse(response.body)
      tandoor_import = TandoorImport.find(body["id"])
      expect(tandoor_import.user).to eq(user)
      expect(tandoor_import.status).to eq("pending")
      expect(tandoor_import.zip_file).to be_attached
    end
  end

  describe "GET /api/v1/tandoor_imports/:id" do
    it "requires a logged-in user" do
      tandoor_import = create(:user).tandoor_imports.create!

      get "/api/v1/tandoor_imports/#{tandoor_import.id}"

      expect(response).to have_http_status(:unauthorized)
    end

    it "404s for another user's import" do
      log_in_as(create(:user))
      other_users_import = create(:user).tandoor_imports.create!

      get "/api/v1/tandoor_imports/#{other_users_import.id}"

      expect(response).to have_http_status(:not_found)
    end

    it "reports progress and results for the current user's import" do
      user = create(:user)
      log_in_as(user)
      recipe = create(:recipe, user: user)
      tandoor_import = user.tandoor_imports.create!(
        status: :completed, processed_recipes: 1, total_recipes: 1, recipe_ids: [ recipe.id ], import_errors: [ "1.zip: bad data" ]
      )

      get "/api/v1/tandoor_imports/#{tandoor_import.id}"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["status"]).to eq("completed")
      expect(body["processed_recipes"]).to eq(1)
      expect(body["total_recipes"]).to eq(1)
      expect(body["recipes"].map { |r| r["id"] }).to eq([ recipe.id ])
      expect(body["errors"]).to eq([ "1.zip: bad data" ])
    end
  end
end
