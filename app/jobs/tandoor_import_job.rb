class TandoorImportJob < ApplicationJob
  queue_as :default

  def perform(tandoor_import_id)
    tandoor_import = TandoorImport.find(tandoor_import_id)
    tandoor_import.update!(status: :processing)

    result = nil
    tandoor_import.zip_file.blob.open do |file|
      result = TandoorImporter.import(
        file.path,
        user: tandoor_import.user,
        on_progress: ->(processed, total) { tandoor_import.update!(processed_recipes: processed, total_recipes: total) }
      )
    end

    tandoor_import.update!(status: :completed, recipe_ids: result.recipes.map(&:id), import_errors: result.errors)
  rescue StandardError => e
    tandoor_import&.update!(status: :failed, import_errors: [ e.message ])
  ensure
    tandoor_import&.zip_file&.purge_later if tandoor_import&.zip_file&.attached?
  end
end
