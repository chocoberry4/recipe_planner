class TandoorImport < ApplicationRecord
  belongs_to :user
  has_one_attached :zip_file

  enum :status, { pending: 0, processing: 1, completed: 2, failed: 3 }
end
