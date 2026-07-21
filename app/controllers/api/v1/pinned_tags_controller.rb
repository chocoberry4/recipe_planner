module Api
  module V1
    # Singleton resource for the current user's pinned tags (Settings.vue) -
    # a curated subset of tags that always shows in the Recipes.vue filter
    # row, since a user with many tags may not want every one of them
    # cluttering that row. `tag_ids` is a full replacement list, same as
    # RecipeUpdater's `tag_names` sync for a recipe's own tags.
    class PinnedTagsController < Api::BaseController
      before_action :require_login

      def show
        render json: pinned_tags_json
      end

      def update
        tag_ids = Array(params[:tag_ids]).map(&:to_i)
        current_user.pinned_tags = Tag.where(id: tag_ids)
        render json: pinned_tags_json
      end

      private

      def pinned_tags_json
        current_user.pinned_tags.order(:name).map { |tag| { id: tag.id, name: tag.name } }
      end
    end
  end
end
