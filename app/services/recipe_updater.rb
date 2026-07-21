# Applies a full edit of a recipe - title/description plus nested
# create/update/destroy of ingredient groups, ingredients (grouped and
# ungrouped), and instructions - in one transaction. Mirrors RecipeImporter's
# ingredient resolution: renaming an ingredient re-resolves it via
# Ingredient.find_or_create_by rather than mutating the shared Ingredient row
# in place, since other recipes may point at the same row by name.
class RecipeUpdater
  Result = Struct.new(:ok, :recipe, :errors, keyword_init: true) do
    def ok?
      ok
    end
  end

  def self.call(recipe, params)
    new(recipe, params).call
  end

  def initialize(recipe, params)
    @recipe = recipe
    @params = params
  end

  def call
    ActiveRecord::Base.transaction do
      @recipe.update!(@params.slice(:title, :description, :image_url))

      upsert_groups(@params[:recipe_ingredient_groups] || [])
      upsert_recipe_ingredients(@params[:ingredients] || [], group: nil)
      upsert_instructions(@params[:instructions] || [])
      # tag_names is a full replacement list, unlike the upserts above - so a
      # partial update that omits it (e.g. the cover-image-only patch from
      # RecipeReview.vue's selectImage) must leave existing tags untouched
      # rather than clearing them.
      sync_tags(@params[:tag_names]) if @params.key?(:tag_names)
    end

    Result.new(ok: true, recipe: @recipe.reload, errors: [])
  rescue ActiveRecord::RecordInvalid => e
    Result.new(ok: false, recipe: nil, errors: e.record.errors.full_messages)
  end

  private

  def destroy_flag?(value)
    ActiveModel::Type::Boolean.new.cast(value)
  end

  def upsert_groups(groups)
    groups.each do |attrs|
      if destroy_flag?(attrs[:_destroy])
        # Any ingredients still nested under a group being destroyed fall
        # back to ungrouped rather than being silently discarded - the
        # frontend is expected to have already moved them out locally, this
        # is just a safety net against data loss if it hasn't.
        upsert_recipe_ingredients(attrs[:recipe_ingredients] || [], group: nil)
        @recipe.recipe_ingredient_groups.find(attrs[:id]).destroy! if attrs[:id].present?
        next
      end

      name = attrs[:name].to_s.strip

      if attrs[:id].blank? && name.blank?
        upsert_recipe_ingredients(attrs[:recipe_ingredients] || [], group: nil)
        next
      end

      group = attrs[:id].present? ? @recipe.recipe_ingredient_groups.find(attrs[:id]) : @recipe.recipe_ingredient_groups.build
      group.update!(name: name, position: attrs[:position])

      upsert_recipe_ingredients(attrs[:recipe_ingredients] || [], group: group)
    end
  end

  def upsert_recipe_ingredients(list, group:)
    list.each do |attrs|
      if destroy_flag?(attrs[:_destroy])
        @recipe.recipe_ingredients.find(attrs[:id]).destroy! if attrs[:id].present?
        next
      end

      next if attrs[:id].blank? && attrs[:name].to_s.strip.blank?

      ingredient = Ingredient.find_or_create_by!(name: attrs[:name].to_s.strip)
      shared = {
        ingredient: ingredient,
        quantity: attrs[:quantity],
        unit: attrs[:unit],
        preparation: attrs[:preparation],
        position: attrs[:position],
        recipe_ingredient_group: group
      }

      if attrs[:id].present?
        @recipe.recipe_ingredients.find(attrs[:id]).update!(shared)
      else
        @recipe.recipe_ingredients.create!(shared)
      end
    end
  end

  # Normalized (stripped/downcased) before lookup, not left to Tag's own
  # before_validation callback, so a re-typed different-cased name (e.g.
  # "Dessert" typed again after "dessert" already exists) resolves to the
  # same row instead of tripping Tag's uniqueness validation.
  def sync_tags(names)
    normalized = names.to_a.map { |name| name.to_s.strip.downcase }.reject(&:empty?).uniq
    @recipe.tags = normalized.map { |name| Tag.find_or_create_by!(name: name) }
  end

  def upsert_instructions(list)
    list.each do |attrs|
      if destroy_flag?(attrs[:_destroy])
        @recipe.instructions.find(attrs[:id]).destroy! if attrs[:id].present?
        next
      end

      next if attrs[:id].blank? && attrs[:description].to_s.strip.blank?

      shared = {
        description: attrs[:description],
        step_number: attrs[:step_number],
        recipe_ingredient_group_id: attrs[:recipe_ingredient_group_id]
      }

      if attrs[:id].present?
        @recipe.instructions.find(attrs[:id]).update!(shared)
      else
        @recipe.instructions.create!(shared)
      end
    end
  end
end
