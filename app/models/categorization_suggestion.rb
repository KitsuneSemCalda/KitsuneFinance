class CategorizationSuggestion < ApplicationRecord
  belongs_to :category
  belongs_to :user

  validates :keyword, presence: true, uniqueness: { scope: :user_id, case_sensitive: false }
end
