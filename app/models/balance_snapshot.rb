class BalanceSnapshot < ApplicationRecord
  belongs_to :user

  validates :snapshot_date, presence: true
  validates :total_balance, presence: true, numericality: true
  validates :total_investments, presence: true, numericality: true
  validates :net_worth, presence: true, numericality: true
  validates :snapshot_date, uniqueness: { scope: :user_id }
end
