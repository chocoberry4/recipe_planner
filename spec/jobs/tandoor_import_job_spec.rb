require "rails_helper"

RSpec.describe TandoorImportJob, type: :job do
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

  def tandoor_import_with_zip(user, recipe_data: nil, raw_bytes: nil)
    tandoor_import = user.tandoor_imports.create!
    bytes = raw_bytes || File.read(build_tandoor_zip(recipe_data).path)
    tandoor_import.zip_file.attach(io: StringIO.new(bytes), filename: "export.zip", content_type: "application/zip")
    tandoor_import
  end

  it "imports the recipe, tracks progress, and marks the import completed" do
    user = create(:user)
    tandoor_import = tandoor_import_with_zip(
      user,
      recipe_data: { name: "Test Recipe", description: "A recipe for testing", steps: [] }
    )

    described_class.perform_now(tandoor_import.id)

    tandoor_import.reload
    expect(tandoor_import.status).to eq("completed")
    expect(tandoor_import.processed_recipes).to eq(1)
    expect(tandoor_import.total_recipes).to eq(1)
    expect(tandoor_import.recipe_ids.size).to eq(1)
    expect(Recipe.find(tandoor_import.recipe_ids.first).title).to eq("Test Recipe")
  end

  it "records import errors without failing the job when a recipe entry is invalid" do
    user = create(:user)
    # No "name" at all - TandoorImporter skips it and reports an error, rather
    # than raising, so the import as a whole still completes.
    tandoor_import = tandoor_import_with_zip(user, recipe_data: { description: "Missing a name" })

    described_class.perform_now(tandoor_import.id)

    tandoor_import.reload
    expect(tandoor_import.status).to eq("completed")
    expect(tandoor_import.recipe_ids).to be_empty
    expect(tandoor_import.import_errors).not_to be_empty
  end

  it "marks the import failed when something unexpected blows up processing it" do
    user = create(:user)
    tandoor_import = tandoor_import_with_zip(user, raw_bytes: "not actually a zip")
    allow(TandoorImporter).to receive(:import).and_raise(StandardError, "boom")

    described_class.perform_now(tandoor_import.id)

    tandoor_import.reload
    expect(tandoor_import.status).to eq("failed")
    expect(tandoor_import.import_errors).to eq([ "boom" ])
  end
end
