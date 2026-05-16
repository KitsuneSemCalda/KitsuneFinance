class Trade < ApplicationRecord
  belongs_to :user
  belongs_to :investment

  validates :trade_type, presence: true, inclusion: { in: %w[buy sell] }
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :date, presence: true

  after_create :update_investment_from_trades
  after_destroy :update_investment_from_trades
  after_update :update_investment_from_trades

  scope :buys, -> { where(trade_type: :buy) }
  scope :sells, -> { where(trade_type: :sell) }
  scope :ordered, -> { order(date: :asc, created_at: :asc) }

  private

  def update_investment_from_trades
    investment.recalculate_from_trades!
  end
end
