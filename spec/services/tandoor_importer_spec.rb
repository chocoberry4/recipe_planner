require "rails_helper"

RSpec.describe TandoorImporter do
  def zip_bytes(entries)
    Zip::OutputStream.write_buffer do |zip|
      entries.each do |name, content|
        zip.put_next_entry(name)
        zip.write(content)
      end
    end.string
  end

  def write_zip(bytes)
    Tempfile.new([ "tandoor-export", ".zip" ]).tap do |tempfile|
      tempfile.binmode
      tempfile.write(bytes)
      tempfile.rewind
    end
  end

  # A single-recipe export: recipe.json directly at the top level, no
  # nested per-recipe zip.
  def single_recipe_zip(recipe_data)
    write_zip(zip_bytes("recipe.json" => recipe_data.to_json))
  end

  # A bulk export: a top-level zip containing one <id>.zip per recipe.
  def bulk_zip(recipes_by_label)
    inner_zips = recipes_by_label.transform_values { |data| zip_bytes("recipe.json" => data.to_json) }
    write_zip(zip_bytes(inner_zips))
  end

  let(:user) { create(:user) }

  it "imports a single-recipe zip, including tags and ingredients" do
    data = {
      name: "Test Recipe",
      description: "A recipe for testing",
      working_time: 10,
      waiting_time: 5,
      keywords: [ { name: "Dinner" }, { name: "dinner" } ],
      steps: [
        { instruction: "Mix everything.", ingredients: [ { food: { name: "Flour" }, amount: 2, unit: { name: "cups" }, note: "sifted" } ] }
      ]
    }

    zip = single_recipe_zip(data)
    result = described_class.import(zip.path, user: user)

    expect(result.ok?).to be true
    expect(result.errors).to be_empty
    recipe = result.recipes.first
    expect(recipe.title).to eq("Test Recipe")
    expect(recipe.duration_minutes).to eq(15)
    expect(recipe.tags.pluck(:name)).to eq([ "dinner" ]) # normalized/deduped against Tandoor's own casing
    expect(recipe.instructions.count).to eq(1)
    ingredient = recipe.recipe_ingredients.first
    expect(ingredient.ingredient.name).to eq("Flour")
    expect(ingredient.quantity).to eq(2)
    expect(ingredient.unit).to eq("cups")
    expect(ingredient.preparation).to eq("sifted")
  end

  # Regression: a real Tandoor export had a trailing step with neither a
  # name nor any instruction text, which used to fail Instruction's
  # description presence validation and take the whole recipe down.
  it "skips a step with no name and no instruction instead of failing the import" do
    data = {
      name: "Recipe With An Empty Step",
      description: "Has a blank trailing step",
      steps: [
        { instruction: "Do the real thing.", ingredients: [] },
        { name: "", instruction: "" }
      ]
    }

    zip = single_recipe_zip(data)
    result = described_class.import(zip.path, user: user)

    expect(result.ok?).to be true
    expect(result.errors).to be_empty
    recipe = result.recipes.first
    expect(recipe.instructions.count).to eq(1)
    expect(recipe.instructions.first.step_number).to eq(1)
    expect(recipe.instructions.first.description).to eq("Do the real thing.")
  end

  it "imports every recipe from a bulk zip-of-zips export" do
    zip = bulk_zip(
      "1.zip" => { name: "First", description: "First recipe" },
      "2.zip" => { name: "Second", description: "Second recipe" }
    )

    result = described_class.import(zip.path, user: user)

    expect(result.ok?).to be true
    expect(result.recipes.map(&:title)).to contain_exactly("First", "Second")
  end

  it "reports a per-recipe error without aborting the rest of a bulk import" do
    zip = bulk_zip(
      "1.zip" => { name: "Good Recipe", description: "Fine" },
      "2.zip" => { description: "No name at all - TandoorImporter skips this one" }
    )

    result = described_class.import(zip.path, user: user)

    expect(result.recipes.map(&:title)).to eq([ "Good Recipe" ])
    expect(result.errors).to contain_exactly("2.zip: missing or invalid recipe.json")
  end

  it "reports progress after each recipe, starting at 0 of the total" do
    zip = bulk_zip(
      "1.zip" => { name: "First", description: "First recipe" },
      "2.zip" => { name: "Second", description: "Second recipe" }
    )
    progress = []

    described_class.import(zip.path, user: user, on_progress: ->(processed, total) { progress << [ processed, total ] })

    expect(progress).to eq([ [ 0, 2 ], [ 1, 2 ], [ 2, 2 ] ])
  end

  it "returns a clean error instead of raising for a file that isn't a zip at all" do
    tempfile = Tempfile.new("not-a-zip").tap { |f| f.write("plain text, not a zip") && f.rewind }

    result = described_class.import(tempfile.path, user: user)

    expect(result.ok?).to be false
    expect(result.errors).to eq([ "That file isn't a valid zip archive." ])
  end
end
