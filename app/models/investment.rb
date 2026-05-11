class Investment < ApplicationRecord
  belongs_to :user

  before_validation :fetch_current_price, on: :create

  validates :name, presence: true
  validates :asset_type, presence: true, inclusion: { in: %w[stock_br fii fixed_income international crypto other] }
  validates :quantity, presence: true, numericality: true
  validates :avg_price, presence: true, numericality: true
  # Make current_price optional during creation to allow automatic population
  validates :current_price, presence: true, on: :update
  validates :current_price, presence: false, on: :create

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
    ((current_value.to_f / total_cost) - 1) * 100
  end

  private

  def fetch_current_price
    return if current_price.present? || ticker.blank?

    price = case asset_type
            when "stock_br", "fii"
              PriceService.fetch_stock_price(ticker)
            when "crypto"
              PriceService.fetch_crypto_price(ticker.downcase)
            end
    
    self.current_price = (price * 100).to_i if price
  end
end
