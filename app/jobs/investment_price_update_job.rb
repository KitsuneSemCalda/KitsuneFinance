class InvestmentPriceUpdateJob < ApplicationJob
  queue_as :default

  def perform
    Investment.find_each do |investment|
      case investment.asset_type
      when "stock_br", "fii"
        price = PriceService.fetch_stock_price(investment.ticker)
        investment.update!(current_price: price) if price
      when "crypto"
        # CoinGecko uses names like 'bitcoin', 'ethereum'.
        # We assume the ticker field contains the ID for crypto if asset_type is crypto.
        price = PriceService.fetch_crypto_price(investment.ticker.downcase)
        investment.update!(current_price: price) if price
      end
    end
  end
end
