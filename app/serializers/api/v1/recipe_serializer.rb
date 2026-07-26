module Api
  module V1
    class RecipeSerializer < ActiveModel::Serializer
      # Ingredients are split across two attributes:
      # - `recipe_ingredient_groups`: sectioned ingredients (e.g. "Marinade"),
      #   each carrying its own ordered `recipe_ingredients`.
      # - `ingredients`: ungrouped recipe_ingredients (recipe_ingredient_group_id IS NULL).
      # Both shapes serialize each recipe_ingredient the same way (via
      # `recipe_ingredient_json`), including `preparation` split out of the
      # ingredient name so later matching logic can key off the clean name.
      # EAGER_LOAD is what every method below needs preloaded to stay
      # N+1-free - pass it to `includes` wherever a Recipe is fetched for
      # this serializer. That alone isn't sufficient though: every accessor
      # here must read the preloaded association arrays in memory (sort_by/
      # select/map) rather than calling .where/.order/.pluck *on* an
      # association, since those always issue a fresh query and silently
      # ignore whatever `includes` already loaded.
      EAGER_LOAD = { recipe_ingredient_groups: {}, recipe_ingredients: :ingredient, instructions: :instruction_ingredients, tags: {}, image_attachment: :blob }.freeze

      attributes :id, :title, :description, :image_url, :user_id, :source_url, :duration_minutes,
                 :recipe_ingredient_groups, :ingredients, :instructions, :tags, :created_at, :updated_at

      # An uploaded file (Recipe#image) wins over the pasted-URL column
      # whenever one is attached - see Recipe's has_one_attached comment. The
      # detail/review/step-mode views this feeds show a larger hero image, so
      # this serves the large variant (caps oversized originals, never
      # upscales) rather than the full original. rails_storage_proxy_path
      # (not rails_representation_path) streams the file through the app
      # instead of redirecting to a short-lived signed disk URL, and sends a
      # real Cache-Control: public, immutable, 100-year header - safe because
      # a blob's key is content-addressed, so a changed image is always a
      # different URL, never a stale cache of one.
      def image_url
        return Rails.application.routes.url_helpers.rails_storage_proxy_path(object.large_variant, only_path: true) if object.image.attached?

        object.image_url
      end

      def tags
        object.tags.sort_by(&:name).map { |tag| { id: tag.id, name: tag.name } }
      end

      def recipe_ingredient_groups
        object.recipe_ingredient_groups.sort_by(&:position).map do |group|
          {
            id: group.id,
            name: group.name,
            position: group.position,
            recipe_ingredients: (ingredients_by_group[group.id] || []).sort_by(&:position).map { |ri| recipe_ingredient_json(ri) }
          }
        end
      end

      def ingredients
        (ingredients_by_group[nil] || []).sort_by(&:position).map { |ri| recipe_ingredient_json(ri) }
      end

      def instructions
        object.instructions.sort_by(&:step_number).map do |instruction|
          {
            id: instruction.id,
            step_number: instruction.step_number,
            description: instruction.description,
            duration_minutes: instruction.duration_minutes,
            image_url: instruction.image_url,
            recipe_ingredient_group_id: instruction.recipe_ingredient_group_id,
            recipe_ingredient_ids: instruction.instruction_ingredients.sort_by(&:id).map(&:recipe_ingredient_id)
          }
        end
      end

      private

      # Grouping object.recipe_ingredients (a single preloaded array) once
      # and keying by recipe_ingredient_group_id (nil for ungrouped) avoids
      # a second association traversal through recipe_ingredient_groups -
      # that would double-load every grouped ingredient's row.
      def ingredients_by_group
        @ingredients_by_group ||= object.recipe_ingredients.group_by(&:recipe_ingredient_group_id)
      end

      def recipe_ingredient_json(recipe_ingredient)
        {
          id: recipe_ingredient.id,
          ingredient_id: recipe_ingredient.ingredient_id,
          name: recipe_ingredient.ingredient.name,
          quantity: recipe_ingredient.quantity,
          unit: recipe_ingredient.unit,
          preparation: recipe_ingredient.preparation,
          position: recipe_ingredient.position
        }
      end
    end
  end
end
