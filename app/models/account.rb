class Account < ApplicationRecord
  belongs_to :user
  has_many :transactions, dependent: :destroy

  validates :name, presence: true
  validates :account_type, presence: true, inclusion: { in: %w[checking savings credit investment cash wallet] }
  validates :balance, presence: true, numericality: true
  validates :currency, presence: true

  scope :total_balance, -> { sum(:balance) }
end
