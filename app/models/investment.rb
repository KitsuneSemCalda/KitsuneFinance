class Investment < ApplicationRecord
  belongs_to :user
  has_many :trades, dependent: :destroy

  before_validation :infer_missing_data, on: :create
  before_validation :fetch_current_price, on: :create

  validates :name, presence: true
  validates :asset_type, presence: true, inclusion: { in: %w[stock_br fii fixed_income international crypto treasury_br treasury_intl other] }
  validates :quantity, presence: true, numericality: true
  validates :avg_price, numericality: true
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

  def recalculate_from_trades!
    buys = trades.buys.order(:date)
    total_qty = 0
    total_cost = 0
    
    buys.each do |trade|
      total_qty += trade.quantity
      total_cost += (trade.quantity * trade.price)
    end
    
    sells = trades.sells
    sold_qty = sells.sum(:quantity)
    
    new_quantity = total_qty - sold_qty
    new_avg_price = total_qty > 0 ? (total_cost / total_qty).to_i : 0
    
    update!(quantity: new_quantity, avg_price: new_avg_price)
  end

  def refresh_current_price!
    price = PriceService.fetch_price(ticker, asset_type, user.brapi_token, price_feed_url: price_feed_url)
    update!(current_price: (price * 100).to_i) if price
  end

  private

  def infer_missing_data
    return if ticker.blank?

    self.asset_type ||= PriceService.infer_asset_type(ticker)
    if name.blank?
      self.name = ticker.upcase
    end
  end

  def fetch_current_price
    return if ticker.blank?
    return if current_price != 0

    price = PriceService.fetch_price(ticker, asset_type, user.brapi_token, price_feed_url: price_feed_url)
    self.current_price = (price * 100).to_i if price
  end
end
