class ExchangeRateService
  BASE_URL = ENV.fetch("EXCHANGE_RATE_URL", "https://economia.awesomeapi.com.br/json")

  def self.fetch_rate(from, to = "BRL")
    pair = "#{from}-#{to}"
    response = Faraday.get("#{BASE_URL}/last/#{pair}") do |req|
      req.options.timeout = 10
      req.options.open_timeout = 5
    end
    return nil unless response.success?

    data = JSON.parse(response.body)
    # AwesomeAPI returns { "USDBRL": { "bid": "5.1234", ... } }
    data.dig(pair.delete("-"), "bid")&.to_f
  rescue StandardError => e
    Rails.logger.error "ExchangeRateService Error: #{e.message}"
    nil
  end
end
