class SyncIndicatorsJob < ApplicationJob
  queue_as :default

  def perform
    # We can store these in Rails.cache or a dedicated model
    # For now, let's just log them or store in cache
    selic = IndicatorsService.fetch_latest(:selic)
    cdi = IndicatorsService.fetch_latest(:cdi)
    ipca = IndicatorsService.fetch_latest(:ipca)

    Rails.cache.write("indicator_selic", selic, expires_in: 1.day) if selic
    Rails.cache.write("indicator_cdi", cdi, expires_in: 1.day) if cdi
    Rails.cache.write("indicator_ipca", ipca, expires_in: 1.month) if ipca

    # Also fetch exchange rates
    usd = ExchangeRateService.fetch_rate("USD")
    eur = ExchangeRateService.fetch_rate("EUR")

    Rails.cache.write("rate_usd", usd, expires_in: 1.hour) if usd
    Rails.cache.write("rate_eur", eur, expires_in: 1.hour) if eur
  end
end
