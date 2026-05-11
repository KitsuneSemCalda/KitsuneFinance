class ExchangeRateService
  BASE_URL = "https://economia.awesomeapi.com.br/json"

  def self.fetch_rate(from, to = "BRL")
    pair = "#{from}-#{to}"
    response = Faraday.get("#{BASE_URL}/last/#{pair}")
    return nil unless response.success?

    data = JSON.parse(response.body)
    # AwesomeAPI returns { "USDBRL": { "bid": "5.1234", ... } }
    data.dig(pair.delete("-"), "bid")&.to_f
  rescue StandardError => e
    Rails.logger.error "ExchangeRateService Error: #{e.message}"
    nil
  end
end
