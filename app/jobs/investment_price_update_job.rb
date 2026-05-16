class InvestmentPriceUpdateJob < ApplicationJob
  queue_as :default

  def perform
    Investment.includes(:user).find_each do |investment|
      price = PriceService.fetch_price(investment.ticker, investment.asset_type, investment.user.brapi_token, price_feed_url: investment.price_feed_url)
      investment.update!(current_price: (price * 100).to_i) if price
    end
  end
end
