module Api
  module V1
    class TandoorImportsController < Api::BaseController
      before_action :require_login
      before_action :require_tandoor_import_enabled

      def create
        file = params[:file]
        return render json: { errors: [ "No file was uploaded" ] }, status: :unprocessable_entity if file.blank?

        tandoor_import = current_user.tandoor_imports.create!
        tandoor_import.zip_file.attach(io: file.tempfile, filename: file.original_filename, content_type: file.content_type)
        TandoorImportJob.perform_later(tandoor_import.id)

        render json: tandoor_import_json(tandoor_import), status: :accepted
      end

      def show
        tandoor_import = current_user.tandoor_imports.find(params[:id])
        render json: tandoor_import_json(tandoor_import)
      end

      private

      def require_tandoor_import_enabled
        render json: { errors: [ "Tandoor import is not enabled" ] }, status: :not_found unless current_user.tandoor_import_enabled?
      end

      def tandoor_import_json(tandoor_import)
        recipes = Recipe.includes(RecipeSerializer::EAGER_LOAD).where(id: tandoor_import.recipe_ids)
        serialized = ActiveModelSerializers::SerializableResource.new(recipes, each_serializer: RecipeSerializer)

        {
          id: tandoor_import.id,
          status: tandoor_import.status,
          total_recipes: tandoor_import.total_recipes,
          processed_recipes: tandoor_import.processed_recipes,
          recipes: serialized.as_json,
          errors: tandoor_import.import_errors
        }
      end
    end
  end
end
