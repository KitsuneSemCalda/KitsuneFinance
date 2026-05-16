class CategorizationRule < ApplicationRecord
  belongs_to :user
  belongs_to :category

  validates :keyword, presence: true, uniqueness: { scope: :user_id, case_sensitive: false },
                      format: { without: /[%_]/, message: "não pode conter caracteres curinga" }

  def self.match(description, user)
    desc_up = description.upcase
    user.categorization_rules.includes(:category).each do |rule|
      return rule.category if desc_up.include?(rule.keyword.upcase)
    end
    nil
  end
end
