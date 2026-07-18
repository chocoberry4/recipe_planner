module Api
  module V1
    # Persists the suggest-and-correct review UI's edits to a recipe's autosort
    # result (ADR-0004). Replaces the full instruction_ingredients set for the
    # recipe in one request rather than diffing individual add/remove/move
    # actions, since the review UI edits a local draft and saves once.
    class InstructionIngredientsController < Api::BaseController
      before_action :require_login
      before_action :find_recipe

      def update
        instruction_ids = @recipe.instructions.pluck(:id)
        assignments = parsed_assignments(instruction_ids)

        ActiveRecord::Base.transaction do
          InstructionIngredient.where(instruction_id: instruction_ids).delete_all
          assignments.each do |instruction_id, recipe_ingredient_ids|
            recipe_ingredient_ids.each do |recipe_ingredient_id|
              InstructionIngredient.create!(instruction_id: instruction_id, recipe_ingredient_id: recipe_ingredient_id)
            end
          end
        end

        render json: Recipe.includes(RecipeSerializer::EAGER_LOAD).find(@recipe.id), serializer: RecipeSerializer
      end

      private

      # A recipe id belonging to someone else 404s rather than 403s - same
      # not-visible-to-you treatment as RecipesController (see its comment).
      def find_recipe
        @recipe = current_user.recipes.find(params[:recipe_id])
      end

      # Only instruction_ids/recipe_ingredient_ids that actually belong to this
      # recipe are honored, so a client can't use this endpoint to link another
      # recipe's rows together (IDOR).
      def parsed_assignments(instruction_ids)
        recipe_ingredient_ids = @recipe.recipe_ingredients.pluck(:id)
        # Not params.require(:assignments) - an empty hash (clear everything)
        # is a valid request but counts as a blank/missing param to Rails.
        raw = params[:assignments]
        raw = raw.respond_to?(:to_unsafe_h) ? raw.to_unsafe_h : (raw || {})

        raw.each_with_object({}) do |(instruction_id, ids), memo|
          iid = instruction_id.to_i
          next unless instruction_ids.include?(iid)

          memo[iid] = Array(ids).map(&:to_i).select { |id| recipe_ingredient_ids.include?(id) }
        end
      end
    end
  end
end
