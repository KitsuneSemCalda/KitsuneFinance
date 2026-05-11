class PriceService
  BRAPI_BASE_URL = "https://brapi.dev/api"
  COINGECKO_BASE_URL = "https://api.coingecko.com/api/v3"

  def self.fetch_stock_price(ticker, token)
    return nil unless token

    response = Faraday.get("#{BRAPI_BASE_URL}/quote/#{ticker}?token=#{token}")
    return nil unless response.success?

    data = JSON.parse(response.body)
    data.dig("results", 0, "regularMarketPrice")
  rescue StandardError => e
    Rails.logger.error "PriceService (Stock) Error: #{e.message}"
    nil
  end

  def self.fetch_crypto_price(coin_id)
    # coin_id example: 'bitcoin', 'ethereum'
    response = Faraday.get("#{COINGECKO_BASE_URL}/simple/price?ids=#{coin_id}&vs_currencies=brl")
    return nil unless response.success?

    data = JSON.parse(response.body)
    data.dig(coin_id, "brl")
  rescue StandardError => e
    Rails.logger.error "PriceService (Crypto) Error: #{e.message}"
    nil
  end
end
