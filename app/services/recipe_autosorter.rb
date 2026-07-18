# Populates `instruction_ingredients` with an initial best-guess assignment of a
# recipe's ingredients to the instruction steps that use them. Implements the
# tiered algorithm from docs/design/recipe-import-and-autosort.md: cheapest and
# most-reliable signal first, each tier only touching ingredients the previous
# tier left unassigned. Genuinely ambiguous ingredients are left unassigned
# (Tier 3) rather than force-guessed — a wrong silent guess is worse than none.
class RecipeAutosorter
  MEASUREMENT_PATTERN = /(\d+\/\d+|\d+(?:\.\d+)?)\s*(#{IngredientLineParser::KNOWN_UNITS.sort_by { |u| -u.length }.join('|')})\b/i

  # Matches "the Marinade" mid-sentence — a lowercase article followed by a
  # Capitalized word is how recipe prose refers to a named section when the
  # source data never encoded that grouping anywhere structured. Deliberately
  # excludes sentence-initial capitals (ordinary capitalization).
  COLLECTIVE_LABEL_PATTERN = /\bthe\s+([A-Z][a-z]+)\b/

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
    backfill_groups_from_matched_instructions
    assign_tier2_5_implied_collective_group
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

  # Not a matching tier - a certainty, not a guess. If Tier 1/2 matched an
  # ingredient to a specific instruction, and that instruction already has a
  # structural group tie (Tier 0's HowToSection data) that the ingredient
  # itself never got (common: a site's JSON-LD groups instructions by
  # section but leaves recipeIngredient a single flat list with no section
  # info at all), the ingredient's group is already a known fact, not
  # something to infer - so backfill it rather than leaving the ingredient
  # correctly assigned to a step but shown as "ungrouped".
  def backfill_groups_from_matched_instructions
    @instructions.each do |instruction|
      next unless instruction.recipe_ingredient_group_id

      instruction.recipe_ingredients.each do |ri|
        next if ri.recipe_ingredient_group_id

        ri.update!(recipe_ingredient_group: instruction.recipe_ingredient_group)
      end
    end
  end

  # Tier 2.5: implied collective group. Covers recipes whose source data never
  # groups ingredients anywhere at all (common: a site visually sections its
  # ingredients but a schema.org recipeIngredient array has no way to encode
  # that) — see docs/design/recipe-import-and-autosort.md "Known limitations".
  # Deliberately scoped to the single-group case only: fires *only* when
  # exactly one collective label is named in prose AND exactly one contiguous
  # run (length >= 2) of still-unassigned ingredients exists. Multiple
  # sections in one recipe can't be reliably paired up by this heuristic
  # (which label goes with which run), so that case is left fully unresolved
  # for manual grouping rather than guessed — silence beats a wrong guess.
  def assign_tier2_5_implied_collective_group
    labels = detect_collective_labels
    runs = contiguous_unassigned_runs
    return unless labels.size == 1 && runs.size == 1

    label = labels.first
    run = runs.first

    group = @recipe.recipe_ingredient_groups.create!(
      name: label,
      position: @recipe.recipe_ingredient_groups.count + 1
    )
    run.each { |ri| ri.update!(recipe_ingredient_group: group) }

    target = primary_instruction_for(label) || first_referencing_instruction(label)
    run.each { |ri| assign(target, ri) } if target
  end

  def detect_collective_labels
    known_tokens = @recipe_ingredients.flat_map { |ri| normalize_tokens(ri.ingredient.name) }.to_set

    labels = []
    @instructions.each do |instruction|
      collective_labels_in(instruction.description).each do |label|
        next if known_tokens.include?(label.downcase.singularize)

        labels << label unless labels.include?(label)
      end
    end
    labels
  end

  def collective_labels_in(text)
    normalized = text.to_s.gsub(/[ \s]+/, " ")
    normalized.scan(COLLECTIVE_LABEL_PATTERN).flatten.uniq
  end

  # A step whose text literally starts with "Label:" (e.g. "Marinade: Combine
  # the Marinade ingredients...") is the section's actual step, as distinct
  # from an earlier step that merely mentions the label in passing (e.g. an
  # "optional" alternate technique). Prefer that over first-mention order.
  def primary_instruction_for(label)
    @instructions.find { |i| i.description.to_s.strip.start_with?("#{label}:") }
  end

  def first_referencing_instruction(label)
    @instructions.find { |i| collective_labels_in(i.description).include?(label) }
  end

  # Maximal runs of still-unassigned ingredients that are contiguous in the
  # recipe's original list order. A lone leftover ingredient isn't a
  # "section" (min length 2) — that's ordinary Tier 3 unresolved.
  def contiguous_unassigned_runs(min_length: 2)
    ordered = @recipe_ingredients.sort_by { |ri| [ ri.position || Float::INFINITY, ri.id ] }

    runs = []
    current = []
    ordered.each do |ri|
      if @assigned_ids.include?(ri.id)
        runs << current if current.size >= min_length
        current = []
      else
        current << ri
      end
    end
    runs << current if current.size >= min_length
    runs
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
