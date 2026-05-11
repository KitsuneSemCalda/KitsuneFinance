class CategorizationRule < ApplicationRecord
  belongs_to :user
  belongs_to :category

  validates :keyword, presence: true, uniqueness: { scope: :user_id, case_sensitive: false }

  def self.match(description, user)
    # Find a rule where the keyword is contained in the description
    rule = user.categorization_rules.joins(:category).find_by("? LIKE '%' || keyword || '%'", description.upcase)
    rule&.category
  end
end
