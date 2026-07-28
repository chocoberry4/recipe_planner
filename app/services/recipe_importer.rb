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
      duration_minutes: extracted.duration_minutes,
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
      duration_minutes: nil,
      user: user,
      source_url: nil
    )
  end

  # A page's own <img> tags are a much bigger, noisier pool than JSON-LD's
  # curated `image` field (nav logos, share icons, related-post thumbnails,
  # tracking pixels) - still capped, just much more generously than
  # JsonLdRecipeExtractor::MAX_IMAGES, since offering more choice is the
  # whole point of scanning the page at all.
  MAX_IMAGE_CANDIDATES = 24

  # Filename/URL keywords for the kind of small chrome images that show up
  # on nearly every page and are never the recipe's own photo.
  NOISE_IMAGE_PATTERN = /logo|icon|sprite|avatar|placeholder|pixel|spacer|tracking|badge|social|share-|blank\.(gif|png)/i

  # Re-fetches a recipe's source page for the review UI's image picker. Not
  # persisted anywhere - called fresh each time it's needed, which also means
  # it stays correct if revisited later even though nothing was cached from
  # the original import. Leads with JSON-LD's `image` field (the site's own
  # best guess at "the" recipe photo) followed by every other <img> found
  # anywhere on the page, so a sparse or wrong JSON-LD image field doesn't
  # limit the picker to nothing useful.
  def self.image_candidates_for(source_url)
    return [] if source_url.blank?

    uri = safe_parse(source_url)
    return [] unless uri

    html = fetch_html(uri)
    return [] unless html

    jsonld_images = JsonLdRecipeExtractor.extract(html)&.image_urls || []
    (jsonld_images + page_image_urls(html, uri)).uniq.first(MAX_IMAGE_CANDIDATES)
  end

  def self.page_image_urls(html, base_uri)
    Nokogiri::HTML(html).css("img").filter_map { |img| resolve_image_src(img, base_uri) }.uniq
  end
  private_class_method :page_image_urls

  # Lazy-loaded images commonly park a tiny placeholder (often a `data:` URI)
  # in `src` and the real image in `data-src` or `srcset` - preferred in that
  # order, falling back to `src` only when it isn't itself a data URI.
  def self.resolve_image_src(img, base_uri)
    return nil if noise_image?(img)

    candidates = [ img["data-src"], largest_srcset_url(img["srcset"]), img["src"] ]
    src = candidates.find { |candidate| candidate.present? && !candidate.start_with?("data:") }
    return nil if src.blank?

    URI.join(base_uri, src).to_s
  rescue URI::InvalidURIError
    nil
  end
  private_class_method :resolve_image_src

  # srcset entries are conventionally ordered smallest-to-largest
  # ("a.jpg 480w, b.jpg 800w, c.jpg 1200w") - the last one is the best
  # candidate for a cover photo.
  def self.largest_srcset_url(srcset)
    srcset.to_s.split(",").filter_map { |part| part.strip.split(/\s+/).first }.last
  end
  private_class_method :largest_srcset_url

  def self.noise_image?(img)
    src = "#{img['src']} #{img['data-src']} #{img['class']}"
    return true if src.match?(NOISE_IMAGE_PATTERN)

    %w[width height].any? { |attr| img[attr].to_i.positive? && img[attr].to_i < 100 }
  end
  private_class_method :noise_image?

  # Checkbox glyphs some recipe sites/plugins prepend to each ingredient when
  # their "printer-friendly"/checklist view gets copy-pasted (e.g. "▢1 garlic
  # clove, minced"), plus generic bullet characters from pasted markdown/word-
  # processor lists. Stripped with no required whitespace after, since sites
  # often glue the glyph directly onto the first character.
  LIST_MARKER_CHARS = %w[▢ □ ☐ ☑ ☒ ✓ ✔ ✗ ✘ • ◦ ‣ ▪ ▫ ● ○ ■ * – —].freeze
  LIST_MARKER_PATTERN = /\A[#{Regexp.escape(LIST_MARKER_CHARS.join)}-]+\s*/

  def self.split_lines(text)
    text.to_s.split(/\r?\n/).map { |line| strip_list_artifacts(line) }.reject(&:empty?)
  end
  private_class_method :split_lines

  # Strips leading numbered-list markers ("1.", "2)") and bullet/checkbox
  # glyphs left over from pasting a formatted list (Word/Google Docs/recipe
  # plugin output) into the plain-text paste form.
  def self.strip_list_artifacts(line)
    cleaned = line.strip
    cleaned = cleaned.sub(/\A\d+[.)]\s+/, "")
    cleaned = cleaned.sub(LIST_MARKER_PATTERN, "")
    cleaned.strip
  end
  private_class_method :strip_list_artifacts

  def self.usable?(extracted)
    extracted && (extracted.ingredient_lines.present? || extracted.instructions.present?)
  end
  private_class_method :usable?

  def self.failure(reason)
    Result.new(ok: false, recipe: nil, reason: reason)
  end
  private_class_method :failure

  def self.persist(title:, description:, ingredient_lines:, instructions:, duration_minutes:, user:, source_url:)
    recipe = nil

    ActiveRecord::Base.transaction do
      recipe = user.recipes.create!(
        title: title.presence || "Imported recipe",
        description: description.presence || default_description(source_url),
        source_url: source_url,
        duration_minutes: duration_minutes
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
      # Applied here (not just in split_lines) so URL imports get the same
      # cleanup as manual paste - some sites' JSON-LD recipeIngredient text
      # embeds the same checkbox/bullet glyphs as their rendered checklist
      # view (e.g. RecipeTinEats' "▢1 garlic clove"), not only copy-pasted text.
      parsed = IngredientLineParser.parse(strip_list_artifacts(line))
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

      recipe.instructions.create!(step_number: index + 1, description: entry.text, image_url: entry.image_url, recipe_ingredient_group: group)
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
