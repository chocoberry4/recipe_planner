require "zip"

# Imports recipes from a Tandoor Recipes (github.com/TandoorRecipes/recipes)
# export .zip. Tandoor's export already hands over fully structured data -
# unlike RecipeImporter's URL/paste paths, there's no fuzzy ingredient-line
# parsing or step-matching autosort involved here: quantity/unit/name are
# already split apart, and each step already carries exactly the ingredients
# used in it.
#
# Two zip shapes are both accepted, since Tandoor's export can be either a
# single recipe or a bulk export of many:
#   - a single recipe: recipe.json + an image file directly at the top level
#   - a bulk export: a top-level zip containing one <id>.zip per recipe, each
#     itself shaped like the single-recipe case above
class TandoorImporter
  Result = Struct.new(:ok, :recipes, :errors, keyword_init: true) do
    def ok?
      ok
    end
  end

  # Generous but bounded - real exports seen so far are tens of KB; this is
  # just a backstop against a malformed/hostile entry claiming a tiny
  # compressed size but an enormous uncompressed one (zip bomb pattern).
  MAX_JSON_BYTES = 20.megabytes

  IMAGE_CONTENT_TYPES_BY_EXTENSION = {
    "jpg" => "image/jpeg",
    "jpeg" => "image/jpeg",
    "png" => "image/png",
    "webp" => "image/webp",
    "gif" => "image/gif"
  }.freeze

  # zip_path: a filesystem path to the uploaded zip (the caller is
  # responsible for getting it there - e.g. an uploaded file's tempfile, or
  # a Tempfile downloaded from an ActiveStorage blob in TandoorImportJob).
  # on_progress: called after each recipe entry is attempted (including
  # failures) with (processed_count, total_count), so a caller running this
  # inside a background job can persist progress for a status endpoint to
  # poll - a bulk export can hold hundreds of recipes with images, each
  # needing several inserts, so this is too slow to run synchronously inside
  # a single request.
  def self.import(zip_path, user:, on_progress: ->(*) { })
    new(zip_path, user, on_progress).import
  end

  def initialize(zip_path, user, on_progress)
    @zip_path = zip_path
    @user = user
    @on_progress = on_progress
  end

  def import
    recipes = []
    errors = []

    Zip::File.open(@zip_path) do |outer_zip|
      recipe_zips = collect_recipe_sources(outer_zip)

      if recipe_zips.empty?
        errors << "No recipe.json found in the uploaded file."
      else
        total = recipe_zips.size
        @on_progress.call(0, total)

        recipe_zips.each_with_index do |(label, files), index|
          recipe = import_one(files)
          recipe ? recipes << recipe : errors << "#{label}: missing or invalid recipe.json"
        rescue JSON::ParserError
          errors << "#{label}: recipe.json isn't valid JSON"
        rescue StandardError => e
          errors << "#{label}: #{e.message}"
        ensure
          @on_progress.call(index + 1, total)
        end
      end
    end

    Result.new(ok: recipes.any?, recipes: recipes, errors: errors)
  rescue Zip::Error
    Result.new(ok: false, recipes: [], errors: [ "That file isn't a valid zip archive." ])
  end

  private

  # A single-recipe export has recipe.json at the top level; a bulk export
  # is a zip of per-recipe .zip entries instead - each handled the same way
  # once unwrapped. Returns [[label, {json:, image:}], ...].
  def collect_recipe_sources(outer_zip)
    top_level = extract_recipe_files(outer_zip)
    return [ [ "recipe", top_level ] ] if top_level[:json]

    outer_zip.glob("*.zip").filter_map do |entry|
      inner_bytes = entry.get_input_stream.read
      # Zip::File.open_buffer's block doesn't hand back the block's return
      # value the way File.open's does - it hands back the buffer/IO
      # regardless, so the extracted result has to be captured into an
      # outer-scope variable instead of relied on as the block's "result".
      files = nil
      Zip::File.open_buffer(inner_bytes) { |inner_zip| files = extract_recipe_files(inner_zip) }
      [ entry.name, files ] if files[:json]
    end
  end

  # Finds recipe.json (by name, case-insensitively) and, among the remaining
  # file entries, the first one that looks like an image by extension -
  # Tandoor's own image filename varies (image.jpg vs image.jpeg seen in
  # practice), so this doesn't assume a fixed name.
  def extract_recipe_files(zip_file)
    json_bytes = nil
    image = nil

    zip_file.each do |entry|
      next unless entry.file?
      next if entry.size > MAX_JSON_BYTES

      if entry.name.downcase == "recipe.json"
        json_bytes = entry.get_input_stream.read
      elsif image.nil?
        ext = File.extname(entry.name).delete_prefix(".").downcase
        content_type = IMAGE_CONTENT_TYPES_BY_EXTENSION[ext]
        image = { bytes: entry.get_input_stream.read, filename: entry.name, content_type: content_type } if content_type
      end
    end

    { json: json_bytes, image: image }
  end

  def import_one(files)
    data = JSON.parse(files[:json])
    return nil unless data["name"].present?

    recipe = nil

    ActiveRecord::Base.transaction do
      recipe = @user.recipes.create!(
        title: data["name"],
        description: data["description"].presence || "Imported from Tandoor.",
        source_url: data["source_url"],
        duration_minutes: total_minutes(data)
      )

      recipe.tags = tag_names(data).map { |name| Tag.find_or_create_by!(name: name) }
      create_steps(recipe, data["steps"] || [])
    end

    attach_image(recipe, files[:image]) if files[:image]
    recipe
  end

  def total_minutes(data)
    total = data["working_time"].to_i + data["waiting_time"].to_i
    total.positive? ? total : nil
  end

  # Tandoor's own tag normalization isn't guaranteed to match this app's
  # (strip/downcase, applied everywhere else a tag gets written - see
  # RecipeUpdater#sync_tags) - applied here too so an imported "Dinner"
  # collapses onto the same row as an existing "dinner" rather than
  # duplicating it.
  def tag_names(data)
    (data["keywords"] || []).map { |kw| kw["name"].to_s.strip.downcase }.reject(&:empty?).uniq
  end

  def create_steps(recipe, steps)
    step_number = 0

    steps.each do |step|
      description = [ step["name"], step["instruction"] ].map(&:presence).compact.join("\n\n")
      # Tandoor allows a step with neither a name nor any instruction text
      # (seen in real exports as a trailing empty step) - there's nothing to
      # import there, so it's skipped rather than failing the whole recipe
      # on Instruction's description presence validation.
      next if description.blank?

      step_number += 1
      instruction = recipe.instructions.create!(step_number: step_number, description: description)

      (step["ingredients"] || []).each_with_index do |ing, position|
        recipe_ingredient = create_recipe_ingredient(recipe, ing, position)
        next unless recipe_ingredient

        InstructionIngredient.create!(instruction: instruction, recipe_ingredient: recipe_ingredient)
      end
    end
  end

  def create_recipe_ingredient(recipe, ing, position)
    name = ing.dig("food", "name").to_s.strip
    return nil if name.blank?

    amount = ing["amount"].to_f
    ingredient = Ingredient.find_or_create_by!(name: name)

    recipe.recipe_ingredients.create!(
      ingredient: ingredient,
      quantity: amount.zero? ? nil : amount,
      unit: ing.dig("unit", "name"),
      preparation: ing["note"].presence,
      position: position + 1
    )
  end

  def attach_image(recipe, image)
    return unless Recipe::ALLOWED_IMAGE_CONTENT_TYPES.include?(image[:content_type])
    return if image[:bytes].bytesize > Recipe::MAX_IMAGE_BYTES

    recipe.image.attach(
      io: StringIO.new(image[:bytes]),
      filename: image[:filename],
      content_type: image[:content_type]
    )
  end
end
