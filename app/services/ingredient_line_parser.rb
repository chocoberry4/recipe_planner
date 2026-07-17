# Parses a raw ingredient line ("1 1/2 cups all-purpose flour, sifted") into
# structured fields. Heuristic, not NLP — see docs/design/recipe-import-and-autosort.md.
# Output feeds an editable form field, so imperfect parses on unusual phrasing are acceptable.
class IngredientLineParser
  Result = Struct.new(:quantity, :unit, :name, :preparation, keyword_init: true)

  UNICODE_FRACTIONS = {
    "¼" => 0.25, "½" => 0.5, "¾" => 0.75,
    "⅓" => 1.0 / 3, "⅔" => 2.0 / 3,
    "⅕" => 0.2, "⅖" => 0.4, "⅗" => 0.6, "⅘" => 0.8,
    "⅙" => 1.0 / 6, "⅚" => 5.0 / 6,
    "⅛" => 0.125, "⅜" => 0.375, "⅝" => 0.625, "⅞" => 0.875
  }.freeze
  FRACTION_CHARS = UNICODE_FRACTIONS.keys.join

  KNOWN_UNITS = %w[
    cup cups
    tablespoon tablespoons tbsp tbsps
    teaspoon teaspoons tsp tsps
    ounce ounces oz
    pound pounds lb lbs
    gram grams g
    kilogram kilograms kg
    milliliter milliliters ml
    liter liters l
    pinch pinches
    dash dashes
    clove cloves
    can cans
    package packages pkg
    slice slices
    stick sticks
    quart quarts qt
    pint pints pt
    gallon gallons gal
    bunch bunches
    head heads
    sprig sprigs
  ].freeze

  def self.parse(line)
    new(line).parse
  end

  def initialize(line)
    @line = line.to_s.strip
  end

  def parse
    return Result.new(quantity: nil, unit: nil, name: nil, preparation: nil) if @line.empty?

    quantity, remainder = extract_quantity(@line)
    unit, remainder = extract_unit(remainder)
    name, preparation = split_name_and_preparation(remainder)

    Result.new(quantity: quantity, unit: unit, name: name, preparation: preparation)
  end

  private

  def extract_quantity(text)
    if (m = text.match(/\A(\d+)?\s*([#{FRACTION_CHARS}])\s+(.*)\z/))
      whole = m[1] ? m[1].to_i : 0
      return [ whole + UNICODE_FRACTIONS[m[2]], m[3] ]
    end

    if (m = text.match(%r{\A(\d+)\s+(\d+)/(\d+)\s+(.*)\z}))
      return [ m[1].to_i + (m[2].to_f / m[3].to_f), m[4] ]
    end

    if (m = text.match(%r{\A(\d+)/(\d+)\s+(.*)\z}))
      return [ m[1].to_f / m[2].to_f, m[3] ]
    end

    if (m = text.match(/\A(\d+(?:\.\d+)?)\s+(.*)\z/))
      return [ m[1].to_f, m[2] ]
    end

    [ nil, text ]
  end

  def extract_unit(text)
    text = text.strip
    return [ nil, text ] if text.empty?

    m = text.match(/\A(\S+)(?:\s+(.*))?\z/)
    candidate = m[1]
    rest = m[2] || ""
    normalized = candidate.downcase.sub(/[.,]\z/, "")

    return [ nil, text ] unless KNOWN_UNITS.include?(normalized)

    [ normalized, rest.sub(/\Aof\s+/i, "") ]
  end

  def split_name_and_preparation(text)
    text = text.strip
    return [ nil, nil ] if text.empty?

    name, _, preparation = text.partition(",")
    name = name.strip
    preparation = preparation.strip

    [ name.empty? ? nil : name, preparation.empty? ? nil : preparation ]
  end
end
