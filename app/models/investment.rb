class Investment < ApplicationRecord
  belongs_to :user

  validates :name, presence: true
  validates :asset_type, presence: true, inclusion: { in: %w[stock_br fii fixed_income international crypto other] }
  validates :quantity, presence: true, numericality: true
  validates :avg_price, presence: true, numericality: true
  validates :current_price, presence: true, numericality: true

  def current_value
    quantity * current_price
  end

  def total_cost
    quantity * avg_price
  end

  def gain_loss
    current_value - total_cost
  end

  def gain_loss_pct
    return 0 if total_cost.zero?
    ((current_value / total_cost) - 1) * 100
  end
end
