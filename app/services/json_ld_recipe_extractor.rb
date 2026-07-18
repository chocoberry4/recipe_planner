# Extracts schema.org/Recipe data from a page's <script type="application/ld+json">
# tags, per docs/adr/0005-jsonld-first-recipe-import.md. Site-agnostic (no per-site
# scrapers) — returns nil if no usable Recipe node is found, signalling the caller
# to fall back to manual paste.
class JsonLdRecipeExtractor
  Result = Struct.new(:title, :description, :ingredient_lines, :instructions, keyword_init: true)
  InstructionEntry = Struct.new(:text, :group_name, keyword_init: true)

  def self.extract(html)
    new(html).extract
  end

  def initialize(html)
    @html = html.to_s
  end

  def extract
    node = recipe_node
    return nil unless node

    Result.new(
      title: clean_text(node["name"]),
      description: clean_text(node["description"]),
      ingredient_lines: Array(node["recipeIngredient"]).map { |line| clean_text(line) },
      instructions: extract_instructions(node["recipeInstructions"])
    )
  end

  private

  # Some sites' JSON-LD embeds raw, undecoded HTML entities in what's meant to
  # be plain text (e.g. RecipeTinEats' recipeInstructions contains literal
  # "&nbsp;" and "&#39;" strings, not real whitespace/apostrophe characters).
  # Nokogiri::HTML.fragment decodes named + numeric entities in one pass;
  # the resulting non-breaking spaces are then flattened to regular spaces
  # and runs of whitespace collapsed.
  def clean_text(text)
    Nokogiri::HTML.fragment(text.to_s).text.gsub(" ", " ").squish
  end

  def recipe_node
    Nokogiri::HTML(@html).css('script[type="application/ld+json"]').each do |script|
      parsed = JSON.parse(script.text)
      node = find_recipe_node(parsed)
      return node if node
    rescue JSON::ParserError
      next
    end

    nil
  end

  def find_recipe_node(parsed)
    nodes = parsed.is_a?(Array) ? parsed : [ parsed ]
    nodes = nodes.flat_map { |n| n.is_a?(Hash) && n["@graph"] ? n["@graph"] : [ n ] }
    nodes.find { |n| n.is_a?(Hash) && recipe_type?(n["@type"]) }
  end

  def recipe_type?(type)
    Array(type).include?("Recipe")
  end

  def extract_instructions(raw)
    case raw
    when String
      raw.split(/\r?\n/).map { |text| clean_text(text) }.reject(&:empty?).map { |text| InstructionEntry.new(text: text, group_name: nil) }
    when Array
      raw.flat_map { |item| extract_instruction_item(item) }
    else
      []
    end
  end

  def extract_instruction_item(item)
    case item
    when String
      [ InstructionEntry.new(text: clean_text(item), group_name: nil) ]
    when Hash
      item["@type"] == "HowToSection" ? extract_section(item) : extract_step(item)
    else
      []
    end
  end

  def extract_section(section)
    Array(section["itemListElement"]).filter_map do |step|
      text = clean_text(step.is_a?(Hash) ? step["text"] : step)
      InstructionEntry.new(text: text, group_name: clean_text(section["name"]).presence) if text.present?
    end
  end

  def extract_step(step)
    text = clean_text(step["text"])
    text.present? ? [ InstructionEntry.new(text: text, group_name: nil) ] : []
  end
end
