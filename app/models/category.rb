class Category < ApplicationRecord
  belongs_to :user
  has_many :transactions, dependent: :nullify
  has_many :budgets, dependent: :destroy
  has_many :categorization_rules, dependent: :destroy
  has_many :categorization_suggestions, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :user_id, message: "já existe para este usuário" }
  validates :transaction_type, presence: true, inclusion: { in: %w[income expense] }

  scope :income, -> { where(transaction_type: "income") }
  scope :expense, -> { where(transaction_type: "expense") }
end
