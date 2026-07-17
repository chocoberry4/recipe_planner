require "net/http"
require "resolv"
require "ipaddr"

# Orchestrates recipe import per docs/adr/0005-jsonld-first-recipe-import.md:
# .from_url fetches a page, extracts schema.org/Recipe JSON-LD, and persists it;
# .from_text is the manual-paste path used both as the JSON-LD fallback and as
# the primary way to write a recipe from scratch. Both funnel through the same
# IngredientLineParser + RecipeAutosorter as the shared building blocks.
class RecipeImporter
  Result = Struct.new(:ok, :recipe, :reason, keyword_init: true) do
    def ok?
      ok
    end
  end

  # Blocks fetching URLs that resolve to internal network ranges, since this
  # endpoint has the app server fetch an arbitrary user-supplied URL — an SSRF
  # vector without this check. Not exhaustive (doesn't pin the resolved IP
  # across the DNS-lookup/connect gap), but blocks the common cases (cloud
  # metadata endpoints, internal services, localhost).
  PRIVATE_RANGES = [
    IPAddr.new("127.0.0.0/8"),
    IPAddr.new("10.0.0.0/8"),
    IPAddr.new("172.16.0.0/12"),
    IPAddr.new("192.168.0.0/16"),
    IPAddr.new("169.254.0.0/16"),
    IPAddr.new("::1/128"),
    IPAddr.new("fc00::/7"),
    IPAddr.new("fe80::/10")
  ].freeze

  def self.from_url(url, user:)
    uri = safe_parse(url)
    return failure(:invalid_url) unless uri

    html = fetch_html(uri)
    return failure(:fetch_failed) unless html

    extracted = JsonLdRecipeExtractor.extract(html)
    return failure(:no_structured_data) unless usable?(extracted)

    persist(
      title: extracted.title,
      description: extracted.description,
      ingredient_lines: extracted.ingredient_lines,
      instructions: extracted.instructions,
      user: user,
      source_url: url
    )
  end

  def self.from_text(title:, description:, ingredients_text:, instructions_text:, user:)
    ingredient_lines = split_lines(ingredients_text)
    instructions = split_lines(instructions_text).map { |text| JsonLdRecipeExtractor::InstructionEntry.new(text: text, group_name: nil) }

    persist(
      title: title,
      description: description,
      ingredient_lines: ingredient_lines,
      instructions: instructions,
      user: user,
      source_url: nil
    )
  end

  def self.split_lines(text)
    text.to_s.split(/\r?\n/).map(&:strip).reject(&:empty?)
  end
  private_class_method :split_lines

  def self.usable?(extracted)
    extracted && (extracted.ingredient_lines.present? || extracted.instructions.present?)
  end
  private_class_method :usable?

  def self.failure(reason)
    Result.new(ok: false, recipe: nil, reason: reason)
  end
  private_class_method :failure

  def self.persist(title:, description:, ingredient_lines:, instructions:, user:, source_url:)
    recipe = nil

    ActiveRecord::Base.transaction do
      recipe = user.recipes.create!(
        title: title.presence || "Imported recipe",
        description: description.presence || default_description(source_url),
        source_url: source_url
      )

      create_ingredients(recipe, ingredient_lines)
      create_instructions(recipe, instructions)
    end

    RecipeAutosorter.call(recipe)
    Result.new(ok: true, recipe: recipe, reason: nil)
  end
  private_class_method :persist

  def self.default_description(source_url)
    source_url ? "Imported from #{source_url}" : "No description provided."
  end
  private_class_method :default_description

  def self.create_ingredients(recipe, lines)
    lines.each_with_index do |line, index|
      parsed = IngredientLineParser.parse(line)
      next if parsed.name.blank?

      ingredient = Ingredient.find_or_create_by!(name: parsed.name)
      recipe.recipe_ingredients.create!(
        ingredient: ingredient,
        quantity: parsed.quantity,
        unit: parsed.unit,
        preparation: parsed.preparation,
        position: index + 1
      )
    end
  end
  private_class_method :create_ingredients

  def self.create_instructions(recipe, instructions)
    groups = {}

    instructions.each_with_index do |entry, index|
      group = entry.group_name.presence && (groups[entry.group_name] ||= recipe.recipe_ingredient_groups.create!(name: entry.group_name, position: groups.size + 1))

      recipe.instructions.create!(step_number: index + 1, description: entry.text, recipe_ingredient_group: group)
    end
  end
  private_class_method :create_instructions

  def self.safe_parse(url)
    uri = URI.parse(url.to_s)
    return nil unless uri.is_a?(URI::HTTP) && uri.host.present? && safe_host?(uri.host)

    uri
  rescue URI::InvalidURIError
    nil
  end
  private_class_method :safe_parse

  def self.safe_host?(host)
    ip = IPAddr.new(Resolv.getaddress(host))
    PRIVATE_RANGES.none? { |range| range.include?(ip) }
  rescue StandardError
    false
  end
  private_class_method :safe_host?

  def self.fetch_html(uri)
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 5, read_timeout: 5) do |http|
      http.get(uri.request_uri)
    end

    response.is_a?(Net::HTTPSuccess) ? response.body : nil
  rescue StandardError
    nil
  end
end
