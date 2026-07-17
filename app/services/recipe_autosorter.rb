# Populates `instruction_ingredients` with an initial best-guess assignment of a
# recipe's ingredients to the instruction steps that use them. Implements the
# tiered algorithm from docs/design/recipe-import-and-autosort.md: cheapest and
# most-reliable signal first, each tier only touching ingredients the previous
# tier left unassigned. Genuinely ambiguous ingredients are left unassigned
# (Tier 3) rather than force-guessed — a wrong silent guess is worse than none.
class RecipeAutosorter
  MEASUREMENT_PATTERN = /(\d+\/\d+|\d+(?:\.\d+)?)\s*(#{IngredientLineParser::KNOWN_UNITS.sort_by { |u| -u.length }.join('|')})\b/i

  def self.call(recipe)
    new(recipe).call
  end

  def initialize(recipe)
    @recipe = recipe
    @instructions = recipe.instructions.order(:step_number).to_a
    @recipe_ingredients = recipe.recipe_ingredients.includes(:ingredient).to_a
    @assigned_ids = Set.new
  end

  def call
    assign_tier0_structural
    assign_tier1_group_prose
    assign_tier2_individual_fuzzy
    self
  end

  private

  def unassigned
    @recipe_ingredients.reject { |ri| @assigned_ids.include?(ri.id) }
  end

  def assign(instruction, recipe_ingredient)
    InstructionIngredient.create!(instruction: instruction, recipe_ingredient: recipe_ingredient)
    @assigned_ids << recipe_ingredient.id
  end

  # Tier 0: source structurally ties the step to a section (HowToSection) —
  # assign every ingredient in that group to that instruction directly.
  def assign_tier0_structural
    @instructions.each do |instruction|
      next unless instruction.recipe_ingredient_group_id

      unassigned.select { |ri| ri.recipe_ingredient_group_id == instruction.recipe_ingredient_group_id }
                .each { |ri| assign(instruction, ri) }
    end
  end

  # Tier 1: no structural link, but the step's prose names a known group
  # ("add the marinade ingredients") — assign the whole group to that step.
  def assign_tier1_group_prose
    @instructions.each do |instruction|
      next if instruction.recipe_ingredient_group_id

      tokens = normalize_tokens(instruction.description)

      @recipe.recipe_ingredient_groups.each do |group|
        name_tokens = normalize_tokens(group.name)
        next if name_tokens.empty? || !name_tokens.all? { |t| tokens.include?(t) }

        unassigned.select { |ri| ri.recipe_ingredient_group_id == group.id }
                  .each { |ri| assign(instruction, ri) }
      end
    end
  end

  # Tier 2: individual fuzzy match on normalized, preparation-stripped names,
  # by whole-token overlap rather than substring (fixes "diced tomatoes" vs
  # "tomatoes, diced"). Duplicate occurrences of the same ingredient are
  # disambiguated by a restated quantity/unit in the step text, falling back
  # to list order.
  def assign_tier2_individual_fuzzy
    @instructions.each do |instruction|
      tokens = normalize_tokens(instruction.description)
      measurement = restated_measurement(instruction.description)

      candidate_ingredient_ids(tokens).each do |ingredient_id|
        occurrences = unassigned.select { |ri| ri.ingredient_id == ingredient_id }
        next if occurrences.empty?

        assign(instruction, pick_occurrence(occurrences, measurement))
      end
    end
  end

  def candidate_ingredient_ids(tokens)
    unassigned.group_by(&:ingredient_id).filter_map do |ingredient_id, ris|
      name_tokens = normalize_tokens(ris.first.ingredient.name)
      ingredient_id if name_tokens.present? && name_tokens.all? { |t| tokens.include?(t) }
    end
  end

  def pick_occurrence(occurrences, measurement)
    return occurrences.first if occurrences.size == 1

    if measurement
      matched = occurrences.find { |ri| measurement_matches?(ri, measurement) }
      return matched if matched
    end

    occurrences.min_by { |ri| [ ri.position || Float::INFINITY, ri.id ] }
  end

  def measurement_matches?(recipe_ingredient, measurement)
    quantity, unit = measurement
    return false if recipe_ingredient.unit.nil? || recipe_ingredient.quantity.nil?

    (recipe_ingredient.quantity.to_f - quantity).abs < 0.01 &&
      recipe_ingredient.unit.downcase == unit.downcase
  end

  def restated_measurement(text)
    match = text.match(MEASUREMENT_PATTERN)
    return nil unless match

    qty_str, unit = match.captures
    quantity = qty_str.include?("/") ? qty_str.split("/").then { |n, d| n.to_f / d.to_f } : qty_str.to_f
    [ quantity, unit ]
  end

  def normalize_tokens(text)
    text.to_s.downcase
        .gsub(/[^a-z0-9\s]/, " ")
        .split
        .map(&:singularize)
  end
end
