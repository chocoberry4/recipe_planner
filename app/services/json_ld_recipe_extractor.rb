# Extracts schema.org/Recipe data from a page's <script type="application/ld+json">
# tags, per docs/adr/0005-jsonld-first-recipe-import.md. Site-agnostic (no per-site
# scrapers) — returns nil if no usable Recipe node is found, signalling the caller
# to fall back to manual paste.
class JsonLdRecipeExtractor
  Result = Struct.new(:title, :description, :ingredient_lines, :instructions, :image_urls, keyword_init: true)
  InstructionEntry = Struct.new(:text, :group_name, :image_url, keyword_init: true)

  # A row of candidate images is meant to be a handful of options to pick
  # from, not every image a page links - caps how many `image` entries get
  # surfaced even if a site's JSON-LD lists many.
  MAX_IMAGES = 8

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
      instructions: extract_instructions(node["recipeInstructions"]),
      image_urls: extract_images(node["image"])
    )
  end

  private

  # schema.org's `image` is polymorphic: a single URL string, an array of
  # URL strings, a single ImageObject ({ "@type": "ImageObject", "url": ... }),
  # or an array of those - any mix. `Array()` on a Hash would wrongly explode
  # it into key/value pairs, so the single-item case is wrapped explicitly
  # rather than relying on Kernel#Array's Hash behavior.
  def extract_images(raw)
    list = raw.is_a?(Array) ? raw : [ raw ]
    list.filter_map { |item| image_url(item) }.uniq.first(MAX_IMAGES)
  end

  def image_url(item)
    case item
    when String
      item.strip.presence
    when Hash
      (item["url"] || item["contentUrl"]).to_s.strip.presence
    end
  end

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
      next unless text.present?

      InstructionEntry.new(text: text, group_name: clean_text(section["name"]).presence, image_url: step_image(step))
    end
  end

  def extract_step(step)
    text = clean_text(step["text"])
    text.present? ? [ InstructionEntry.new(text: text, group_name: nil, image_url: step_image(step)) ] : []
  end

  # A HowToStep's own `image` is the same polymorphic shape as the recipe-level
  # `image` (see extract_images above) - reused here and just take the first
  # match, since a single step only gets one photo.
  def step_image(step)
    extract_images(step.is_a?(Hash) ? step["image"] : nil).first
  end
end
